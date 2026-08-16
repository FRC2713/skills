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
- Never request or print passwords, personal access tokens, authentication tokens, or complete environment dumps.
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

Detect the OS, architecture, shell, current directory, WSL status, Git, Node, npm, GitHub CLI, GitHub authentication, available disk, and access to `FRC2713/hawk-app-template`.

Read [references/platform-setup.md](references/platform-setup.md) when a prerequisite is missing, outdated, or split across Windows and WSL. Do not prescribe an install before identifying the actual platform and existing package/version manager.

Report one compact table with **Ready**, **Needs attention**, and **Optional** sections. Explain tools by purpose:

- Git downloads and tracks the app.
- Node 24 LTS and npm run it.
- GitHub CLI is needed only to create and save a separate GitHub repository.

If Node is available, run the bundled read-only check from the skill directory:

```text
node scripts/preflight.mjs --destination <absolute-destination>
```

If Node is missing, perform the same checks directly and run the script after Node is installed. Never treat Docker, Playwright browsers, an editor, or compiler tools as initial requirements.

Repair one prerequisite at a time. Before an installation, state the exact software, source, command, privilege/restart implications, and affected system area. Ask permission, run it only after approval, then recheck. Never use `sudo npm install -g`, opaque `curl | sh`, TLS bypasses, or `npm audit fix --force`.

## 3. Choose destination and saving

Recommend an unsynchronized local folder such as `~/Projects/<name>` and show its resolved absolute path. In WSL, keep it under the Linux home directory, never `/mnt/c`. Refuse an existing destination; do not merge or overwrite it.

Ask whether to save the app to GitHub now. Recommend a **private** repository and explain that private means only invited people can see it. If the user prefers local-only, explain that it is not yet backed up online.

For GitHub creation, derive the authenticated account. Default to that personal account; use an organization only when the user chooses it and membership/access checks succeed. Check that the proposed repository does not already exist.

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

Do not upgrade dependencies. If native SQLite compilation fails, diagnose the exact error before proposing a compiler toolchain. Treat the unchanged template failing `npm run check` as a baseline problem; do not personalize the app until it passes.

## 6. Write the app brief and identity

Read `START_HERE.md`, the example `APP_BRIEF.md`, `docs/BRANDING.md`, and `docs/features/projects.md`. Explain that Projects is a working example, not the requested product.

Interview one question at a time to replace `APP_BRIEF.md`:

1. Who uses it?
2. What are the two or three essential things they need to do?
3. What information must it remember?
4. What should the first version explicitly not do?
5. What visible result would make it successful?

Offer examples when the user is unsure. Present the completed brief for approval before changing application code.

After approval, personalize only the template identity: package name and lockfile root metadata, `.hawk/app.yaml`, visible product name/description, favicon accessibility label, and README title. Follow `docs/BRANDING.md`; keep the replaceable `H` monogram and never invent a team logo. Do not remove the example CRUD feature until its replacement has an approved feature plan.

Run `npm run check` after identity changes. Do not commit or push without a separate explicit yes. Before any requested publication, inspect the diff and likely secrets, confirm Git identity, and summarize exactly what will be saved.

## 7. Start locally and hand off

Start `npm run dev` on loopback, wait for the printed URL, and verify `/health` returns success. If port 3000 is busy, explain that the app is ready and offer a different port. Tell the user how to stop it and how to restart it.

Finish with a receipt:

- app name and purpose;
- exact local folder;
- GitHub URL and visibility, or “not yet saved to GitHub”;
- local browser URL;
- checks that passed;
- `data/app.db` as local app data;
- whether changes are committed/pushed;
- the next suggested prompt: “Plan the smallest useful first feature from APP_BRIEF.md. Do not implement it yet.”

Do not deploy or alter Hawk Suite as part of this skill.
