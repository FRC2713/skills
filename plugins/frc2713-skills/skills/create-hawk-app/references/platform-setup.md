# Platform setup and recovery

Read only the section matching the detected environment. Prefer already-installed official package/version managers. Never introduce a package manager, version manager, WSL, VM, compiler toolchain, or global configuration merely for convenience.

## Shared requirements

- Read the template's `package.json` after creation and obey its `engines.node`; the current baseline is Node 24 or newer.
- Install Node and npm together. Never install npm separately or use `sudo npm install -g`.
- Use browser-based GitHub authentication. Never ask for a token or run a command that prints one.
- Reopen the terminal or agent after an installer changes PATH, then resume at the failed phase.
- Test access to the actual private template, not generic internet connectivity.

Official sources:

- Node: <https://nodejs.org/en/download>
- Git: <https://git-scm.com/downloads>
- GitHub CLI: <https://cli.github.com/>
- GitHub authentication: <https://cli.github.com/manual/gh_auth_login>

## Native Windows

Stay in PowerShell/native Windows. Do not introduce WSL for this workflow.

When `winget` already exists, these are reasonable after explicit approval:

```powershell
winget install --id Git.Git -e --source winget
winget install --id OpenJS.NodeJS.LTS -e --source winget
winget install --id GitHub.cli -e --source winget
```

Confirm the offered Node LTS satisfies the template before installing. Otherwise use the official installers above. An installer may request administrator approval and a terminal restart.

Keep the destination outside OneDrive when possible. Do not create SSH keys or modify global Git identity during preflight.

## macOS

Apple's `xcode-select --install` supplies Git through a visible system installer. Use `brew install git`, `brew install node@24`, or `brew install gh` only when Homebrew already exists and the user approves. Do not install Homebrew as an incidental prerequisite.

If Homebrew's Node is not the required major version, use the official Node installer or an already-configured version manager. Do not silently change `.zshrc` or `.bashrc`.

## Linux

Read `/etc/os-release` before proposing a command. Use the detected distribution's supported package manager for Git. Check the candidate Node version before installing because stable distributions may ship an older major version.

If an existing `nvm`, `fnm`, or similar manager is configured, use it after approval. Do not bootstrap a version manager with a remote shell pipeline. Otherwise direct the user to the official Node download and explain any manual PATH step.

Use GitHub CLI's official signed-repository instructions for the detected distribution. Do not assume Snap is installed.

## WSL

Stay entirely inside WSL: Linux Git, Linux Node/npm, Linux GitHub CLI, and a destination beneath the Linux home directory such as `~/Projects`. Do not mix Windows executables with a WSL repository and do not place `node_modules` beneath `/mnt/c`, `/mnt/d`, or another mounted Windows drive.

Installing or changing WSL itself is out of scope. Use the Linux section for the detected distribution.

## GitHub access

Check without exposing credentials:

```text
gh auth status --hostname github.com
gh api repos/FRC2713/hawk-app-template --jq '{name,private,is_template,default_branch}'
```

If authentication is missing, explain that a browser window will connect the GitHub account, ask permission, then use:

```text
gh auth login --hostname github.com --web
gh auth setup-git
```

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
