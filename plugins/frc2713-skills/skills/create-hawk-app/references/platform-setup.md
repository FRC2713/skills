# Platform setup and recovery

Read only the section matching the detected environment. Prefer already-installed official package/version managers. Never introduce a package manager, version manager, WSL, VM, compiler toolchain, or global configuration merely for convenience.

## Shared requirements

- The required Node major version is `NODE_MAJOR` in `scripts/preflight.sh`. Once the app exists, its `package.json` `engines.node` field is the authority instead.
- Install Node and npm together. Never install npm separately or use `sudo npm install -g`.
- Prefer an install that needs no password or administrator prompt. See "Installing without a password" below; it is the recommended path on every platform, Windows included.
- You cannot answer a privilege prompt. `sudo` needs a real terminal to read a password, and a Windows administrator prompt needs a click on a dialog you cannot see; neither your shell nor an in-session `!` prompt can supply either. Hand the exact command to the user for their own terminal window, tell them to come back when it finishes, and verify the result yourself.
- Use browser-based GitHub authentication. Never ask for a token or run a command that prints one.
- After an installer or profile edit changes PATH, your own shell does not see it. Record the absolute `bin` directory and prefix later commands with it — on Windows, prepend it to `$env:Path` for the session.
- To confirm what a *new* terminal window would see, start an interactive shell: `bash -ic` or `zsh -ic`, never `bash -lc`. Ubuntu's `.bashrc` returns early for non-interactive shells, so a login shell reports failure for a change that actually worked. On Windows, read the user-scope value back with `[Environment]::GetEnvironmentVariable('Path','User')`.
- Test access to the actual private template, not generic internet connectivity.

Official sources:

- Node: <https://nodejs.org/en/download>
- Git: <https://git-scm.com/downloads>
- GitHub CLI: <https://cli.github.com/>
- GitHub authentication: <https://cli.github.com/manual/gh_auth_login>

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

**Putting it on PATH.** This is a change to the user's environment, so show the exact edit and ask first.

- macOS and Linux: append one `export PATH=...` line to the shell's own profile — `~/.zshrc` for macOS's default zsh, `~/.bashrc` for most Linux and WSL2. Read the file first, back it up, then append. Confirm with `zsh -ic` or `bash -ic`.
- `~/.local/bin` is often already on PATH. Check before proposing a change for the GitHub CLI; frequently none is needed.
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

Windows installations leak onto the Linux PATH, so `node`, `npm`, or `gh` may appear to exist while actually pointing at a Windows program under `/mnt/<drive>/`. `scripts/preflight.sh` flags this. The failure is confusing on its own — Windows npm called from Linux reports `WSL 1 is not supported`, which has nothing to do with the real problem — so name it plainly: the terminal is finding the Windows copy, a Linux copy is needed, and the Windows one will be left alone.

Installing or changing WSL itself is out of scope. Use the Linux section for the detected distribution.

## GitHub access

The template is private. The GitHub CLI is therefore required for every path through this skill, including local-only: without it the template cannot be downloaded at all. Say that plainly rather than presenting sign-in as optional.

Check without exposing credentials:

```text
gh auth status --hostname github.com 2>&1 | sed -E 's/(gho_|ghp_|ghu_|ghs_|github_pat_)[A-Za-z0-9_]*/[redacted]/g'
gh api repos/FRC2713/hawk-app-template --jq '{name,private,is_template,default_branch}'
```

Pipe any command that may print a token through that redaction, every time.

If sign-in succeeds but the template still returns `Not Found`, the account is authenticated and simply lacks access. That is a dead end you cannot repair: tell the user a mentor or team lead must add them to the FRC2713 organization or share the repository with them, and stop.

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
