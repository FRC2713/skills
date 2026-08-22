---
name: create-hawk-app
description: Guide a non-programmer from an app idea to a working local Hawk application using FRC2713/hawk-app-template. Perform OS and tool preflight checks, safely guide prerequisite installation, create a separate private GitHub repository or local clone, install dependencies, interview for APP_BRIEF.md, personalize the app, verify it, and start it locally. Use when someone invokes $create-hawk-app, asks to create/start/scaffold a Hawk app, or needs first-time setup from the Hawk app template. Do not use to deploy or modify an established app.
---

# Create a Hawk app

Act as the operator and guide. Assume the user has never programmed or used Git. Explain outcomes in ordinary language; do not make them translate technical output.

## Interaction rules

- Ask one short question at a time. Offer a recommended answer and explain its effect.
- Inspect facts instead of asking for them. Detect the OS, shell, accounts, tools, and paths.
- Preserve answers across errors and allow the user to revise them.
- Before any consequential action, show exactly what will change and ask permission.
- Never silently install software, elevate privileges, edit shell profiles, create an online repository, overwrite a folder, commit, push, expose a server, or deploy.
- Never request or print passwords, personal access tokens, authentication tokens, or complete environment dumps. Redact any token that appears in command output.
- Hand any command needing `sudo` to the user to run in their own terminal window. Neither your shell nor an in-session `!` prompt can accept a password. Prefer an install that needs no password at all, and offer the `sudo` route only as the alternative.
- After installing a tool outside the default `PATH`, record its absolute `bin` directory in the phase checklist and prefix every later command with it. Editing a profile does not change the shell you are already running in.
- Verify that any command you hand the user actually exists in this template before you print it.
- Distinguish “on this computer,” “saved on GitHub,” and “deployed.” A local server is not deployed.

Keep a private phase checklist so retries resume at the failed phase:

1. idea and name
2. computer check
3. destination and GitHub choice
4. creation
5. baseline verification
6. app brief and identity
7. local launch and handoff

## 1. Establish the idea

Start with: “I’ll check your computer, create a safe copy of the Hawk template, verify it, and help describe your app. I’ll ask before installing anything or creating files or GitHub repositories.”

Ask what the app should help someone do. From the answer, propose:

- a short human-facing name;
- a lowercase hyphenated repository name;
- one sentence describing its purpose.

Ask the user to accept or change that proposal before continuing. Avoid the word “slug.”

## 2. Run read-only preflight checks

This skill supports macOS, Linux, WSL2, and native Windows. Detect which one you are on before anything else, and never assume a POSIX shell.

Run the bundled read-only check first, from the skill directory. It needs no Node, installs nothing, and prints no credentials. Pick the one matching the platform:

```text
sh scripts/preflight.sh --destination <absolute-destination>                       # macOS, Linux, WSL2
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/preflight.ps1 -Destination <absolute-destination>   # native Windows
```

Both print the same report and use the same exit codes: 0 when everything is ready, 1 when something needs attention, 2 for bad arguments. Prefer `pwsh` over `powershell` when it is present. `-ExecutionPolicy Bypass` applies to that one process only and needs no administrator rights; say so if the user asks.

The script is a convenience, not a dependency. If it fails to run at all, say so plainly, perform the same checks inline from [references/platform-setup.md](references/platform-setup.md), and carry on — never let a broken helper end the session.

Check the destination phase 3 will recommend, resolved to an absolute path: `~/Projects/<repository-name>` on macOS, Linux, and WSL2, or `%USERPROFILE%\Projects\<repository-name>` on Windows. Phase 3 confirms or changes it.

`NODE_MAJOR` in `preflight.sh` and `$NodeMajor` in `preflight.ps1` are the authority on the required Node version until the app exists; after that, the created `package.json` `engines` field is. The two must always agree.

Read [references/platform-setup.md](references/platform-setup.md) when a prerequisite is missing, outdated, shadowed by a Windows copy, or split across Windows and WSL. Do not prescribe an install before identifying the actual platform and existing package/version manager. Never assume a distribution's packaged Node is new enough; check the version it actually offers.

Restate the script's report as one compact table with **Ready** and **Needs attention** sections. Explain tools by purpose:

- Git downloads and tracks the app.
- Node and npm run it.
- GitHub CLI signs in to GitHub. It is **required, not optional**: the template is a private repository, so even an app that never leaves this computer cannot be downloaded without it.

Never treat Docker, Playwright browsers, an editor, or compiler tools as initial requirements.

Repair one prerequisite at a time. Before an installation, state the exact software, source, command, privilege/restart implications, and affected system area. Ask permission, run it only after approval, then re-run the script. Never use `sudo npm install -g`, opaque `curl | sh`, TLS bypasses, or `npm audit fix --force`.

Clear every finding except the destination before leaving this phase; the destination is settled in phase 3. Do not enter phase 4 until the script exits 0 for the destination the user actually approved.

If the template is unreachable while the GitHub CLI is signed in, the account simply lacks access. Say plainly that a mentor or team lead has to add them to the FRC2713 organization or share the repository with them, and stop there. Do not improvise a way around it.

## 3. Choose destination and saving

Recommend an unsynchronized local folder — `~/Projects/<name>` on macOS and Linux, `%USERPROFILE%\Projects\<name>` on Windows — and show its resolved absolute path. In WSL2, keep it under the Linux home directory, never `/mnt/c`. On Windows, keep it outside OneDrive. Refuse a destination that already contains files; do not merge or overwrite it. An existing empty folder is fine.

Ask whether to save the app to GitHub now. Recommend a **private** repository and explain that private means only invited people can see it. If the user prefers local-only, explain that it is not yet backed up online.

For GitHub creation, derive the authenticated account. Default to that personal account; use an organization only when the user chooses it and membership/access checks succeed. Check that the proposed repository does not already exist.

Re-run `scripts/preflight.sh` against the chosen destination once it is settled, and require it to exit 0.

Present a final review containing name, purpose, absolute folder, GitHub owner and visibility (or local-only), plus the actions about to run. Ask “Create my app?” before any write.

## 4. Create an independent app

Use `https://github.com/FRC2713/hawk-app-template` as the source of truth. Do not use a fork.

### GitHub-backed path

Require `gh auth status --hostname github.com` to succeed. Query the source repository and confirm it is marked as a GitHub template. Then:

1. Create the approved owner/name repository with `gh repo create ... --template FRC2713/hawk-app-template` and the approved visibility. Do not use `--public` unless the user explicitly chose public.
2. Clone the new repository into the exact approved destination.
3. Verify `origin` points to the new owner/name repository, not `FRC2713/hawk-app-template`.

Repository creation is an external write and must follow the final review. If the remote succeeds but cloning fails, keep the remote, report its URL, and retry only the clone phase.

Use literal, validated values in the equivalent of these commands rather than unresolved shell variables:

```text
gh repo create OWNER/NAME --template FRC2713/hawk-app-template --private --description "PURPOSE"
gh repo clone OWNER/NAME ABSOLUTE_DESTINATION
```

If the source is not marked as a template, do not improvise a fork or silently carry its remote. Offer the local-only path and tell a maintainer that the GitHub repository must be marked as a template before clean GitHub-backed creation is available.

### Local-only path

Clone the template into the exact new destination using authenticated `gh repo clone` when available, or a clone URL whose access was already verified. Verify that the clone's `origin` is exactly the Hawk template, then remove that remote. Keep the template snapshot commit; do not delete `.git` or rewrite history. Verify `git remote -v` is empty. Explain that a separate GitHub remote can be added later.

Never delete a partially created folder automatically. On failure, say which phase failed, confirm what remains safe, and offer to retry, choose another path, or remove the partial result only with explicit permission.

## 5. Verify the untouched baseline

Inside the new app, verify that `AGENTS.md`, `START_HERE.md`, `APP_BRIEF.md`, `docs/BRANDING.md`, `package.json`, and `package-lock.json` exist. Read `AGENTS.md` before editing anything.

Run `npm run doctor` first so its plain-language report establishes the missing-dependency state. Explain that `npm ci` downloads the app's locked packages only into this folder, ask permission, then run:

```text
npm ci
npm run doctor
npm run check
```

Do not upgrade dependencies. Treat the unchanged template failing `npm run check` as a baseline problem; do not personalize the app until it passes.

If a native package such as `better-sqlite3` fails to build, work this ladder in order and stop at the first step that yields a working module:

1. Re-run `npm ci` once. Install-script policy and leftover state differ between runs.
2. Run `npm ci --ignore-scripts`, then load-test each native dependency directly, for example `node -e "new (require('better-sqlite3'))(':memory:')"`. Quote it for the shell you are actually in; PowerShell and POSIX shells disagree about nested quotes.
3. Look inside `node_modules/<package>/prebuilds/`. Many packages ship ready-made binaries in the npm tarball itself. What a project publishes on its GitHub Releases page is not evidence about what npm delivers.

Propose a compiler toolchain only once a module genuinely fails to load. It is a system-wide change that costs the user a password prompt and dozens of packages; do not spend that on a guess.

## 6. Write the app brief and identity

Read `START_HERE.md`, the example `APP_BRIEF.md`, `docs/BRANDING.md`, and `docs/features/projects.md`. Explain that Projects is a working example, not the requested product.

Interview one question at a time to replace `APP_BRIEF.md`:

1. Who uses it?
2. What are the two or three essential things they need to do?
3. What information must it remember?
4. What should the first version explicitly not do?
5. What visible result would make it successful?

Offer examples when the user is unsure.

If the described product needs something the template does not demonstrate — a drawing surface, an outside data source, file uploads, live updates between devices — say so plainly in ordinary language and confirm it is still what they want. Record decisions you would otherwise be guessing at under an **Open questions** heading in the brief; they belong to feature planning, not to this interview.

Present the completed brief for approval before changing application code.

After approval, personalize only the template identity: package name and lockfile root metadata, `.hawk/app.yaml`, visible product name/description, favicon accessibility label, and README title. Follow `docs/BRANDING.md`; keep the replaceable `H` monogram and never invent a team logo. Do not remove the example CRUD feature until its replacement has an approved feature plan.

Run `npm run check` after identity changes. Do not commit or push without a separate explicit yes. Before any requested publication, inspect the diff and likely secrets, confirm Git identity, and summarize exactly what will be saved.

## 7. Start locally and hand off

Start `npm run dev` on loopback, wait for the printed URL, and verify `/health` returns success. If port 3000 is busy, explain that the app is ready and offer a different port. Tell the user how to stop it and how to restart it, using commands you have confirmed this template supports.

The brief and identity changes are still uncommitted at this point. Offer to make the first commit and recommend it, showing what would be saved. A novice does not know that commits exist, so waiting to be asked leaves their work unprotected.

Finish with a receipt:

- app name and purpose;
- exact local folder;
- GitHub URL and visibility, or “not yet saved to GitHub”;
- local browser URL;
- checks that passed;
- `data/app.db` as local app data;
- whether changes are committed/pushed;
- the next suggested prompt: “Plan the smallest useful first feature from APP_BRIEF.md. Do not implement it yet.”

If the app is local-only, make the absence of any backup the last thing you say, not a row in the middle of a table.

Do not deploy or alter Hawk Suite as part of this skill.
