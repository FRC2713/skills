# Platform setup and recovery

Read only the section matching the detected environment. Prefer already-installed official package/version managers. Never introduce a package manager, version manager, WSL, VM, compiler toolchain, or global configuration merely for convenience.

## Shared requirements

- The required Node major version is `NODE_MAJOR` in `scripts/preflight.sh`. Once the app exists, its `package.json` `engines.node` field is the authority instead.
- Install Node and npm together. Never install npm separately or use `sudo npm install -g`.
- Prefer an install that needs no password or administrator prompt. See "Installing without a password" below; it is the recommended path on every platform, Windows included.
- You cannot answer a privilege prompt. `sudo` needs a real terminal to read a password, and a Windows administrator prompt needs a click on a dialog you cannot see; neither your shell nor an in-session `!` prompt can supply either. Hand the exact command to the user for their own terminal window, tell them to come back when it finishes, and verify the result yourself.
- Use browser-based GitHub authentication. Never ask for a token or run a command that prints one.
- After an installer or profile edit changes PATH, your own shell does not see it. Record the absolute `bin` directory and prefix later commands with it — on Windows, prepend it to `$env:Path` for the session.
- A newly installed tool has to be visible to **two** different shells, and they can disagree. Check both:
  - `bash -ic 'command -v node'` (or `zsh -ic`) — what a *new terminal window* the user opens will see.
  - `bash -c 'command -v node'` — what *your own tool calls* will see, and what a coding agent in this folder will see in later sessions.

  Ubuntu's `.bashrc` returns early for non-interactive shells, so anything appended to the bottom of it — which is where `nvm` and most installers write — satisfies the first check and fails the second. When that happens you must prefix every remaining command with the tool's absolute `bin` directory for the rest of the session, and the next session has the same problem. Prefer an arrangement where both checks pass; see "Putting it on PATH" below. On Windows, read the user-scope value back with `[Environment]::GetEnvironmentVariable('Path','User')`.
- Test access to the actual private template, not generic internet connectivity.

Official sources:

- Node: <https://nodejs.org/en/download>
- Git: <https://git-scm.com/downloads>
- GitHub CLI: <https://cli.github.com/>
- GitHub authentication: <https://cli.github.com/manual/gh_auth_login>

## Choosing how to install Node

Decide in this order, and do not offer the user a menu that inverts it:

1. **A version manager they already have configured** — `nvm`, `fnm`, `asdf`, `mise`. Use it after approval.
2. **The no-password install below.** This is the default choice when nothing is already set up.
3. **The distribution's or platform's package manager**, but only after checking the version it actually offers.

Nothing else. In particular, do not bootstrap a version manager the user does not already have by piping a script from the internet into a shell — `curl … | bash` is exactly the pattern SKILL.md forbids, and installing `nvm` that way also appends to the bottom of `~/.bashrc`, below the early return for non-interactive shells, which leaves Node invisible to your own commands and to every later session in that folder. When you present this choice, present option 2 as the recommendation.

## Installing without a password

This is the recommended way to supply Node and the GitHub CLI on every platform. It touches nothing outside the user's own account, needs no password or administrator prompt, and is undone by deleting a folder. Ask permission first, and explain that everything lands in their user folder and nowhere else.

The shape is the same everywhere: pick the version, download the official archive *and* its published checksum file, verify before unpacking, unpack into a user-owned folder, then put that folder on PATH with the user's approval.

**Node.** Read <https://nodejs.org/dist/index.json>, pick the newest release that is marked LTS and satisfies the required major version, and tell the user the exact version. Download the matching archive and `SHASUMS256.txt` from `https://nodejs.org/dist/<version>/`:

| Platform | Archive | Unpack into |
| --- | --- | --- |
| macOS | `node-<version>-darwin-arm64.tar.gz` or `-darwin-x64.tar.gz` | `~/.local/node` |
| Linux, WSL2 | `node-<version>-linux-x64.tar.xz` or `-linux-arm64.tar.xz` | `~/.local/node` |
| Windows | `node-<version>-win-x64.zip` or `-win-arm64.zip` | `%LOCALAPPDATA%\node` |

Map `uname -m` or `PROCESSOR_ARCHITECTURE` to Node's own names: `x86_64` and `AMD64` are `x64`; `aarch64` and `ARM64` are `arm64`. Verify the checksum before unpacking and show the user that it passed; stop if it does not. Refuse if the destination folder already exists.

**GitHub CLI.** Read <https://api.github.com/repos/cli/cli/releases/latest> and take the archive for the platform and architecture, plus the `gh_<version>_checksums.txt` beside it. Linux builds are `gh_<version>_linux_<arch>.tar.gz`; macOS and Windows builds are `.zip` (`gh_<version>_macOS_arm64.zip`, `gh_<version>_windows_amd64.zip`). Verify, then place only the `gh` binary: into `~/.local/bin` on macOS, Linux, and WSL2, or `%LOCALAPPDATA%\gh\bin` on Windows.

**Putting it on PATH.** The best outcome is not having to. `~/.local/bin` is already on PATH on macOS and on most Linux and WSL2 systems, including through the non-interactive shells that profile edits miss.

- **Preferred, and no profile edit at all:** after unpacking Node into `~/.local/node`, symlink its three entry points into `~/.local/bin`:

  ```sh
  ln -s ~/.local/node/bin/node ~/.local/bin/node
  ln -s ~/.local/node/bin/npm  ~/.local/bin/npm
  ln -s ~/.local/node/bin/npx  ~/.local/bin/npx
  ```

  Confirm `~/.local/bin` is genuinely on PATH first, and confirm afterwards with **both** shells from the rule above. This is why the GitHub CLI install — a single binary dropped into `~/.local/bin` — needs no profile edit and causes no trouble later.
- Only if `~/.local/bin` is not on PATH: append one `export PATH=...` line to the shell's own profile — `~/.zshrc` for macOS's default zsh, `~/.bashrc` for most Linux and WSL2. Read the file first, back it up, then append. Tell the user plainly that a `.bashrc` edit is invisible to non-interactive shells, so tools running in this folder will still need the absolute path.
- This is a change to the user's environment either way, so show the exact edit and ask first.
- Windows: set the user-scope variable, which needs no administrator rights, and show this exact command before running it:

  ```powershell
  [Environment]::SetEnvironmentVariable('Path', "$env:LOCALAPPDATA\node;" + [Environment]::GetEnvironmentVariable('Path','User'), 'User')
  ```

  It affects only this user and takes effect in new terminals. For the session already open, also prepend it to `$env:Path`.

Neither step logs in to anything. Authentication is separate and comes after.

## Native Windows

Stay in PowerShell/native Windows. Do not introduce WSL for this workflow.

Use `scripts/preflight.ps1` here; `preflight.sh` will not run. It works on Windows PowerShell 5.1, which ships with Windows 10 and 11, and on PowerShell 7. If it fails to run for any reason, check by hand instead and report the same Ready / Needs attention table: OS, architecture and PowerShell version; `git --version`; `node --version` against the required major; `npm --version`; `gh --version` and `gh auth status --hostname github.com`; whether the destination exists, is empty, and has an existing parent; free space on its drive; whether the destination sits inside OneDrive; and whether `gh api repos/FRC2713/hawk-app-template --jq '.is_template'` returns `true`.

The no-password install above works here too and is the first choice. When `winget` already exists and the user prefers it, these are reasonable after explicit approval:

```powershell
winget install --id Git.Git -e --source winget
winget install --id OpenJS.NodeJS.LTS -e --source winget
winget install --id GitHub.cli -e --source winget
```

Confirm the offered Node LTS satisfies the required major version before installing. Otherwise use the official installers above. Any of these may raise an administrator prompt and require a terminal restart — you cannot click that prompt, so hand the command to the user and verify afterwards.

Keep the destination outside OneDrive; `preflight.ps1` checks for this. Syncing thousands of `node_modules` files breaks installs and fills the user's cloud storage. Do not create SSH keys or modify global Git identity during preflight.

## macOS

Apple's `xcode-select --install` supplies Git through a visible system installer. Use `brew install git`, `brew install node@<required-major>`, or `brew install gh` only when Homebrew already exists and the user approves. Do not install Homebrew as an incidental prerequisite.

If Homebrew's Node is not the required major version, prefer the no-password install above, an already-configured version manager, or the official Node installer. Do not silently change `.zshrc` or `.bashrc`; the default shell on current macOS is zsh, so read and edit `~/.zshrc` unless the user's shell says otherwise.

Apple Silicon reports `arm64` from `uname -m`; Intel Macs report `x86_64`, which Node calls `x64`. Do not hand an Intel build to an Apple Silicon Mac.

## Linux

Read `/etc/os-release` before proposing a command. Use the detected distribution's supported package manager for Git.

Never assume the distribution's Node is new enough. Check what it actually offers first — on Debian and Ubuntu, `apt-cache policy nodejs` — and say the number out loud. Ubuntu 24.04, for example, offers Node 18, which is too old. If the packaged version is too old, do not propose it.

Prefer "Installing without a password" above for Node and the GitHub CLI. It avoids a password prompt entirely and is the path most likely to succeed on the first try.

If an existing `nvm`, `fnm`, or similar manager is already configured, use it after approval. Do not bootstrap a version manager with a remote shell pipeline.

A system-wide install through a vendor repository is a reasonable second choice when the user prefers it, but every step of it needs `sudo`, so the whole command goes to the user's own terminal window. Do not assume Snap is installed.

## WSL2

Stay entirely inside WSL2: Linux Git, Linux Node/npm, Linux GitHub CLI, and a destination beneath the Linux home directory such as `~/Projects`. Do not mix Windows executables with a WSL2 repository and do not place `node_modules` beneath `/mnt/c`, `/mnt/d`, or another mounted Windows drive.

Windows installations leak onto the Linux PATH, so `node`, `npm`, or `gh` may appear to exist while actually pointing at a Windows program under `/mnt/<drive>/`. `scripts/preflight.sh` flags this. The failure is confusing on its own — Windows npm called from Linux reports `WSL 1 is not supported. Please upgrade to WSL 2 or above.` even on a machine that is genuinely running WSL 2, which has nothing to do with the real problem — so name it plainly the first time it appears: the terminal is finding the Windows copy, a Linux copy is needed, and the Windows one will be left alone. Expect that message to surface again during installs; it stays harmless.

Installing or changing WSL itself is out of scope. Use the Linux section for the detected distribution.

## GitHub access

The template is public, so downloading it needs Git and nothing else — no GitHub account, no GitHub
CLI, no sign-in. Everything in this section applies **only** when the user has chosen to save their
own app on GitHub. Do not install the GitHub CLI, and do not raise sign-in at all, for a user who
said no.

If preflight reports that the template is reachable only with a saved GitHub sign-in, it has been
made private again: a maintainer needs to make it public. Anyone on this computer can still proceed
because their credentials are already stored, but a student on a fresh machine could not, so say so
rather than letting it pass silently.

Check without exposing credentials:

```text
gh auth status --hostname github.com 2>&1 | sed -E 's/(gho_|ghp_|ghu_|ghs_|github_pat_)[A-Za-z0-9_]*/[redacted]/g'
gh api repos/FRC2713/hawk-app-template --jq '{name,private,is_template,default_branch}'
```

Pipe any command that may print a token through that redaction, every time.

If sign-in succeeds but the template still returns `Not Found`, the account is authenticated and simply lacks access — which should only happen if the repository was made private again. Tell the user a mentor or team lead must make it public, or add them to the FRC2713 organization, and stop. The this-computer-only path does not need any of this and is worth offering first.

If authentication is missing, explain that a browser window will connect the GitHub account, ask permission, then use:

```text
gh auth login --hostname github.com --web
gh auth setup-git
```

Like `sudo`, this needs a real terminal: it prints a one-time code, waits for the user to press Enter, and opens a browser. Hand it over rather than running it yourself. Walk them through what to expect — the code, the browser page, the confirmation — and mention that under WSL the browser may not open on its own, in which case the printed URL can be pasted into Windows' browser and works the same. Verify the result yourself when they return.

Explain that `gh auth setup-git` connects Git's HTTPS access to the approved GitHub CLI login. Treat that global credential configuration as part of the authentication change and ask before running it.

Do not run `gh auth token`, use `--show-token`, paste tokens into prompts, or upload SSH keys automatically.

## Recovery language

Use this order:

1. Say what failed in human terms.
2. Say what remains safe and whether anything was created.
3. Name the failed phase: computer setup, GitHub creation, download, package install, app check, or server start.
4. Recommend one repair and one retry action.
5. Keep raw diagnostics available under “technical details,” not as the main explanation.

Never restart the interview or discard earlier choices after a repair.
