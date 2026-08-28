---
name: create-hawk-app
description: Guide a non-programmer from an app idea to a working local Hawk application using FRC2713/hawk-app-template. Perform OS and tool preflight checks, safely guide prerequisite installation, download the template into a new local folder, optionally save it to a private GitHub repository, install dependencies, interview for APP_BRIEF.md, personalize the app, verify that it actually renders, and start it locally. GitHub is optional throughout. Use when someone invokes $create-hawk-app, asks to create/start/scaffold a Hawk app, or needs first-time setup from the Hawk app template. Do not use to deploy or modify an established app.
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
- Write scratch files — diagnostic scripts, screenshots, logs — outside the user's app folder. Their new repository should contain their app and nothing you left behind.
- Distinguish “on this computer,” “saved on GitHub,” and “deployed.” A local server is not deployed.

Keep a private phase checklist so retries resume at the failed phase:

1. idea, name, and whether to use GitHub
2. computer check
3. destination and final review
4. creation
5. baseline verification (including whether Git knows who the user is)
6. app brief and identity
7. local launch, render check, and handoff

## 1. Establish the idea

Start with: “I’ll check your computer, create a safe copy of the Hawk template, verify it, and help describe your app. I’ll ask before installing anything or creating files or GitHub repositories.”

Ask what the app should help someone do. From the answer, propose:

- a short human-facing name;
- a lowercase hyphenated repository name;
- one sentence describing its purpose.

Ask the user to accept or change that proposal before continuing. Avoid the word “slug.”

Then ask one more question, because the answer decides which tools are needed at all: **do they
want the app saved on GitHub?** Recommend a private repository and explain that private means only
invited people can see it, and that GitHub is a backup living somewhere other than this computer.
Local-only is a perfectly good answer — the app works exactly the same, it simply is not backed up
anywhere, and it can be put on GitHub later.

Record the answer as yes, no, or unknown, and pass it to preflight in phase 2. Only a yes makes the
GitHub CLI necessary.

## 2. Run read-only preflight checks

This skill supports macOS, Linux, WSL2, and native Windows. Detect which one you are on before anything else, and never assume a POSIX shell.

Run the bundled read-only check first, from the skill directory. It needs no Node, installs nothing, and prints no credentials. Pick the one matching the platform:

```text
sh scripts/preflight.sh --destination <absolute-destination> --github <yes|no|unknown>                                        # macOS, Linux, WSL2
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/preflight.ps1 -Destination <absolute-destination> -GitHub <yes|no|unknown>   # native Windows
```

Pass the GitHub answer from phase 1. It decides whether a missing or signed-out GitHub CLI is a
blocker or merely worth mentioning, and it defaults to `no`.

Both print the same report and use the same exit codes: 0 when everything is ready, 1 when something needs attention, 2 for bad arguments. The report has three sections: **Ready**, **Worth knowing**, and **Needs attention**. Only the last one blocks — pass a "Worth knowing" line on to the user as information and keep going; do not try to clear it. Prefer `pwsh` over `powershell` when it is present. `-ExecutionPolicy Bypass` applies to that one process only and needs no administrator rights; say so if the user asks.

The script is a convenience, not a dependency. If it fails to run at all, say so plainly, perform the same checks inline from [references/platform-setup.md](references/platform-setup.md), and carry on — never let a broken helper end the session.

Check the destination phase 3 will recommend, resolved to an absolute path: `~/Projects/<repository-name>` on macOS, Linux, and WSL2, or `%USERPROFILE%\Projects\<repository-name>` on Windows. Phase 3 confirms or changes it.

`NODE_MAJOR` in `preflight.sh` and `$NodeMajor` in `preflight.ps1` are the authority on the required Node version until the app exists; after that, the created `package.json` `engines` field is. The two must always agree.

**Read [references/platform-setup.md](references/platform-setup.md) before proposing any install.** Not "if you get stuck" — before. It carries the preferred install order, the no-password install, and the PATH rules that decide whether the tools you install are visible to you afterwards. A run that skipped it installed Node somewhere its own shell could not see and prefixed the next twenty-five commands with an absolute path. Do not prescribe an install before identifying the actual platform and existing package/version manager. Never assume a distribution's packaged Node is new enough; check the version it actually offers.

Restate the script's report as one compact table with **Ready** and **Needs attention** sections. Explain tools by purpose:

- Git downloads and tracks the app.
- Node and npm run it.
- GitHub CLI signs in to GitHub. It is **optional**, and only needed if the user chose in phase 1 to save their app on GitHub. Downloading the template needs Git and nothing else. Do not install it here for a user who said no or has not decided; phase 3 installs it just in time if the answer is yes.

Never treat Docker, Playwright browsers, an editor, or compiler tools as initial requirements. That rule is about *preflight* — none of them are needed to create and run an app. It is not a rule against ever installing one: if the user reports that the app looks wrong, seeing the page yourself is the fastest way to a correct answer, and `npx playwright install chromium` is a legitimate step at that point. Say what it costs before proposing it — roughly 115 MB, and on Linux or WSL also `libnss3`, `libnspr4`, and `libasound2t64`, which need a `sudo apt-get` the user must run in their own terminal. Playwright's test API is imported from `@playwright/test`, not `playwright`.

Repair one prerequisite at a time. Before an installation, state the exact software, source, command, privilege/restart implications, and affected system area. Ask permission, run it only after approval, then re-run the script. Never use `sudo npm install -g`, opaque `curl | sh`, TLS bypasses, or `npm audit fix --force`.

Clear every **Needs attention** finding except the destination before leaving this phase; the destination is settled in phase 3. "Worth knowing" lines are not findings to clear. Do not enter phase 4 until the script exits 0 for the destination the user actually approved.

If preflight reports that the template can only be reached with a saved GitHub sign-in, the template repository has been made private again. Say plainly that a maintainer needs to make it public, and that until then the skill needs a GitHub account that has been granted access. If the user has such an account, carry on down the GitHub path; otherwise stop there. Do not improvise a way around it.

## 3. Choose the destination and confirm

Recommend an unsynchronized local folder — `~/Projects/<name>` on macOS and Linux, `%USERPROFILE%\Projects\<name>` on Windows — and show its resolved absolute path. In WSL2, keep it under the Linux home directory, never `/mnt/c`. On Windows, keep it outside OneDrive. Refuse a destination that already contains files; do not merge or overwrite it. An existing empty folder is fine.

The GitHub question was answered in phase 1. Do not ask it again. If the answer was **unknown**, settle it now, before the final review.

Only if the answer is yes: install the GitHub CLI if it is missing, sign in, then derive the authenticated account. Default to that personal account; use an organization only when the user chooses it and membership/access checks succeed. Check that the proposed repository does not already exist.

Re-run preflight against the chosen destination once it is settled, passing the settled `--github` answer, and require it to exit 0.

Present a final review containing name, purpose, absolute folder, GitHub owner and visibility (or “this computer only”), plus the actions about to run. Ask “Create my app?” before any write.

## 4. Create an independent app

Use `https://github.com/FRC2713/hawk-app-template` as the source of truth. Do not use a fork. Which of the two paths below applies was decided in phase 1.

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

If the source is not marked as a template, do not improvise a fork or silently carry its remote. Offer the this-computer-only path instead — it does not depend on the template flag at all — and tell a maintainer that the GitHub repository must be marked as a template before clean GitHub-backed creation is available.

### This-computer-only path

This path needs no GitHub account and no GitHub CLI. Clone the template into the exact new
destination with plain Git:

```text
git clone https://github.com/FRC2713/hawk-app-template ABSOLUTE_DESTINATION
```

Then verify that the clone's `origin` is exactly the Hawk template, and remove that remote so
nothing the user does can ever reach back to it. Keep the template snapshot commit; do not delete
`.git` or rewrite history. Verify `git remote -v` prints nothing. Explain that a GitHub remote can
be added later, and that until then this folder is the only copy.

Never delete a partially created folder automatically. On failure, say which phase failed, confirm what remains safe, and offer to retry, choose another path, or remove the partial result only with explicit permission.

## 5. Verify the untouched baseline

Inside the new app, verify that `AGENTS.md`, `START_HERE.md`, `APP_BRIEF.md`, `docs/BRANDING.md`, `package.json`, and `package-lock.json` exist. Read `AGENTS.md` before editing anything.

While you are here, read `git config user.name` and `git config user.email` and record whether they
are set. Do not ask about them yet — phase 7 needs the answer, and discovering it there turns one
question into two at the worst possible moment.

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

Start `npm run dev` on loopback and wait for the printed URL. If port 3000 is busy, explain that the app is ready and offer a different port. Tell the user how to stop it and how to restart it, using commands you have confirmed this template supports.

### Confirm it actually renders

`/health` returning 200 means the server answered, not that the app looks like anything. Neither does `npm run check`: that builds for production, and so do the browser tests, while the dev server you just started is the thing the user will actually open. The two can disagree — a run once declared an app "built and working" over a page with no styling applied at all.

So, in order:

1. Run `npm run check:render` against the running dev server. It reports whether the page's styles will actually be applied and whether its stylesheets arrive.
2. If that script does not exist — an app made from an older copy of the template — do the same check by hand: fetch `/`, read the `content-security-policy` response header, and if the page carries inline `<style>` blocks while `style-src` lists neither `'unsafe-inline'` nor any `sha256-` hash, the browser will block every one of them and the page will render as unformatted text.
3. Ask the user to open the URL and confirm what they see: the app name in a header band, panels with borders, ordinary sans-serif text. Wait for their yes.

Do not call the app working, verified, or done before step 3 answers. If it looks wrong, say plainly that you cannot see the page and ask what is wrong before changing anything, rather than inferring problems from the HTML.

### Offer the first commit, once

The brief and identity changes are still uncommitted. Offer the first commit and recommend it, showing what would be saved — a novice does not know that commits exist, so waiting to be asked leaves their work unprotected.

Ask this as **one** question, not two. If phase 5 found that Git has no `user.name` or `user.email`, put the name and email you propose inside that same question rather than asking again after they agree; use `git config --local` so nothing outside this folder changes. Offer three answers: commit now, skip for now, or skip Git entirely.

If the user declines, accept it in one line, record it in the receipt, and **do not ask again**. It is not a failure and not a risk worth relitigating — they have been told the work is unsaved, and that is enough.

### Receipt

Finish with a receipt:

- app name and purpose;
- exact local folder;
- GitHub URL and visibility, or “not saved to GitHub”;
- local browser URL;
- checks that passed, including that the user confirmed the page looks right;
- `data/app.db` as local app data;
- whether changes are committed;
- the next suggested prompt: “Plan the smallest useful first feature from APP_BRIEF.md. Do not implement it yet.”

If the app is on this computer only, make the absence of any backup the last thing you say, not a row in the middle of a table.

### Where this skill stops

The receipt is the end. This skill creates an app; it does not build features in it.

If the user asks for the first feature in the same breath — and they will, because they are excited and the app is right there — start it as a *plan*, not as code. That is what the suggested prompt asks for, what `START_HERE.md` step 2 describes, and what `AGENTS.md` requires: one behavior specification in `docs/features/`, approved by the user, before any implementation. A previous run slid from handoff into building an entire feature in a single turn and skipped that gate.

Do not deploy or alter Hawk Suite as part of this skill.
