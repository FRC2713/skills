#!/usr/bin/env node

import { accessSync, constants, existsSync, readdirSync, statfsSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";

const TEMPLATE = "https://github.com/FRC2713/hawk-app-template.git";
const args = process.argv.slice(2);
const destinationIndex = args.indexOf("--destination");
const json = args.includes("--json");
const skipNetwork = args.includes("--skip-network");

if (destinationIndex === -1 || !args[destinationIndex + 1]) {
  console.error("Usage: node preflight.mjs --destination <path> [--json] [--skip-network]");
  process.exit(2);
}

function expandHome(value) {
  if (value === "~") return os.homedir();
  if (value.startsWith(`~${path.sep}`)) return path.join(os.homedir(), value.slice(2));
  return value;
}

function run(command, commandArgs, timeout = 15_000) {
  const executable = process.platform === "win32" && command === "npm" ? "npm.cmd" : command;
  const result = spawnSync(executable, commandArgs, {
    encoding: "utf8",
    timeout,
    windowsHide: true,
    env: { ...process.env, GIT_TERMINAL_PROMPT: "0" },
  });
  return {
    ok: result.status === 0,
    output: `${result.stdout ?? ""}\n${result.stderr ?? ""}`.trim(),
    timedOut: result.error?.code === "ETIMEDOUT",
  };
}

function nearestExistingParent(candidate) {
  let current = candidate;
  while (!existsSync(current)) {
    const parent = path.dirname(current);
    if (parent === current) return undefined;
    current = parent;
  }
  return current;
}

const results = [];
function add(level, check, detail) {
  results.push({ level, check, detail });
}

const destination = path.resolve(expandHome(args[destinationIndex + 1]));
const release = os.release().toLowerCase();
const isWsl = Boolean(process.env.WSL_DISTRO_NAME) || release.includes("microsoft");
const platform = isWsl ? "WSL" : `${os.type()} ${os.release()}`;
add("ready", "Computer", `${platform}, ${os.arch()}`);

const git = run("git", ["--version"]);
add(git.ok ? "ready" : "attention", "Git", git.ok ? git.output.split("\n")[0] : "Not available");

const nodeMajor = Number(process.versions.node.split(".")[0]);
add(nodeMajor >= 24 ? "ready" : "attention", "Node", `${process.versions.node}${nodeMajor < 24 ? "; Node 24 or newer is required" : ""}`);

const npm = run("npm", ["--version"]);
add(npm.ok ? "ready" : "attention", "npm", npm.ok ? npm.output.split("\n")[0] : "Not available with Node");

const gh = run("gh", ["--version"]);
let githubAuthenticated = false;
if (!gh.ok) {
  add("optional", "GitHub CLI", "Not available; required only for GitHub-backed creation");
} else {
  const auth = run("gh", ["auth", "status", "--hostname", "github.com"]);
  githubAuthenticated = auth.ok;
  add(auth.ok ? "ready" : "optional", "GitHub", auth.ok ? "CLI is signed in" : "CLI is installed but not signed in");
}

if (existsSync(destination)) {
  let empty = false;
  try {
    empty = readdirSync(destination).length === 0;
  } catch {
    empty = false;
  }
  add(empty ? "attention" : "attention", "Destination", empty ? `${destination} already exists, even though it is empty; choose a new path` : `${destination} already contains files; nothing will be changed`);
} else {
  const parent = nearestExistingParent(path.dirname(destination));
  if (!parent) {
    add("attention", "Destination", `No existing parent was found for ${destination}`);
  } else {
    try {
      accessSync(parent, constants.W_OK);
      add("ready", "Destination", `${destination} is new; parent folder is writable`);
      const disk = statfsSync(parent);
      const freeBytes = Number(disk.bavail) * Number(disk.bsize);
      const freeGb = freeBytes / 1024 ** 3;
      add(freeGb >= 1 ? "ready" : "attention", "Disk space", `${freeGb.toFixed(1)} GB available near the destination`);
    } catch {
      add("attention", "Destination", `The parent of ${destination} is not writable`);
    }
  }
}

if (isWsl && destination.startsWith("/mnt/")) {
  add("attention", "WSL location", "Choose a folder under the Linux home directory, not /mnt/*");
}

if (skipNetwork) {
  add("optional", "Template access", "Skipped by request");
} else if (!git.ok) {
  add("attention", "Template access", "Cannot check until Git is available");
} else {
  const access = githubAuthenticated
    ? run("gh", ["api", "repos/FRC2713/hawk-app-template", "--silent"], 20_000)
    : run("git", ["ls-remote", "--exit-code", TEMPLATE, "HEAD"], 20_000);
  add(access.ok ? "ready" : "attention", "Template access", access.ok ? "FRC2713/hawk-app-template is reachable" : access.timedOut ? "GitHub access timed out" : "The private template was not reachable; check GitHub authentication");
}

if (json) {
  console.log(JSON.stringify({ destination, results }, null, 2));
} else {
  console.log(`Hawk app preflight for ${destination}\n`);
  for (const level of ["ready", "attention", "optional"]) {
    const items = results.filter((result) => result.level === level);
    if (!items.length) continue;
    const title = level === "ready" ? "Ready" : level === "attention" ? "Needs attention" : "Optional";
    console.log(`${title}:`);
    for (const item of items) console.log(`  ${level === "ready" ? "✓" : level === "attention" ? "!" : "·"} ${item.check}: ${item.detail}`);
    console.log();
  }
}

process.exitCode = results.some((result) => result.level === "attention") ? 1 : 0;
