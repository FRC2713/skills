#!/bin/sh
# Read-only preflight for create-hawk-app.
# Installs nothing, changes nothing, prints no credentials.
#
# Covers macOS, Linux, and WSL. Native Windows uses preflight.ps1; the two
# are twins, so any check added here belongs there too.
#
# Written in POSIX sh on purpose: this has to run *before* Node exists,
# which is exactly the moment its answers matter most. Keep it POSIX --
# it is run by BSD sh on macOS as well as by bash and dash on Linux.
#
# NODE_MAJOR below is the single source of truth for the required Node
# version. The created app's package.json "engines" field takes over once
# the app exists.

set -u

NODE_MAJOR=24
TEMPLATE_REPO="FRC2713/hawk-app-template"

DESTINATION=""
SKIP_NETWORK=0

# Whether the user has chosen to save their app on GitHub. The template itself
# is public, so an app that never leaves this computer needs no GitHub account
# and no GitHub CLI at all -- "no" and "unknown" must not block the run.
GITHUB=no

usage() {
  echo "Usage: sh preflight.sh --destination <path> [--github yes|no|unknown] [--skip-network]" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --destination)
      if [ $# -lt 2 ]; then usage; exit 2; fi
      DESTINATION="$2"; shift 2 ;;
    --github)
      if [ $# -lt 2 ]; then usage; exit 2; fi
      case "$2" in
        yes|no|unknown) GITHUB="$2" ;;
        *) echo "--github must be yes, no, or unknown" >&2; exit 2 ;;
      esac
      shift 2 ;;
    --skip-network) SKIP_NETWORK=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

[ -n "$DESTINATION" ] || { usage; exit 2; }

case "$DESTINATION" in
  "~") DESTINATION="$HOME" ;;
  "~/"*) DESTINATION="$HOME/${DESTINATION#\~/}" ;;
esac
case "$DESTINATION" in
  /*) ;;
  *) DESTINATION="$(pwd)/$DESTINATION" ;;
esac

TMP=$(mktemp "${TMPDIR:-/tmp}/hawk-preflight.XXXXXX") || exit 2
trap 'rm -f "$TMP"' EXIT INT TERM

add() { printf '%s|%s|%s\n' "$1" "$2" "$3" >>"$TMP"; }

# Can this repository be read with no account at all? Ambient credentials would
# otherwise make a private repository look reachable to everyone.
anonymous_ls_remote() {
  GIT_TERMINAL_PROMPT=0 \
  GIT_ASKPASS=true \
  GIT_CONFIG_GLOBAL=/dev/null \
  GIT_CONFIG_SYSTEM=/dev/null \
    git ls-remote --exit-code -h "$1" >/dev/null 2>&1
}

# A path under /mnt/<drive>/ in WSL is a Windows program, not a Linux one.
is_windows_path() {
  case "$1" in
    /mnt/?/*) return 0 ;;
    *) return 1 ;;
  esac
}

# --- computer ------------------------------------------------------------

KERNEL=$(uname -s 2>/dev/null || echo unknown)
KERNEL_RELEASE=$(uname -r 2>/dev/null || echo unknown)
ARCH=$(uname -m 2>/dev/null || echo unknown)

IS_WSL=0
case "$KERNEL_RELEASE" in *[Mm]icrosoft*|*WSL*) IS_WSL=1 ;; esac
[ -n "${WSL_DISTRO_NAME:-}" ] && IS_WSL=1

DISTRO=""
if [ -r /etc/os-release ]; then
  DISTRO=$(. /etc/os-release 2>/dev/null; printf '%s' "${PRETTY_NAME:-}")
fi

if [ "$IS_WSL" -eq 1 ]; then
  PLATFORM="WSL — ${DISTRO:-${WSL_DISTRO_NAME:-unknown Linux}}"
elif [ "$KERNEL" = Darwin ]; then
  MACOS_VERSION=$(sw_vers -productVersion 2>/dev/null || true)
  PLATFORM="macOS ${MACOS_VERSION:-$KERNEL_RELEASE}"
elif [ -n "$DISTRO" ]; then
  PLATFORM="$DISTRO"
else
  PLATFORM="$KERNEL $KERNEL_RELEASE"
fi

# Report the architecture the way Node names its downloads, so the label
# and the file to fetch cannot disagree.
case "$ARCH" in
  x86_64|amd64) ARCH_LABEL="x64 ($ARCH)" ;;
  arm64|aarch64) ARCH_LABEL="arm64 ($ARCH)" ;;
  *) ARCH_LABEL="$ARCH" ;;
esac
add ready "Computer" "$PLATFORM, $ARCH_LABEL"

# --- git -----------------------------------------------------------------

if command -v git >/dev/null 2>&1; then
  add ready "Git" "$(git --version 2>/dev/null | head -1)"
else
  add attention "Git" "Not installed"
fi

# --- node and npm --------------------------------------------------------

NODE_BIN=$(command -v node 2>/dev/null || true)
if [ -z "$NODE_BIN" ]; then
  add attention "Node" "Not installed; Node $NODE_MAJOR or newer is required"
elif [ "$IS_WSL" -eq 1 ] && is_windows_path "$NODE_BIN"; then
  add attention "Node" "Only Windows' copy is on PATH ($NODE_BIN); Node $NODE_MAJOR must be installed inside Linux"
else
  NODE_VERSION=$(node --version 2>/dev/null | tr -d 'v')
  NODE_FOUND=${NODE_VERSION%%.*}
  case "$NODE_FOUND" in
    ''|*[!0-9]*)
      add attention "Node" "Found at $NODE_BIN but its version could not be read" ;;
    *)
      if [ "$NODE_FOUND" -ge "$NODE_MAJOR" ]; then
        add ready "Node" "$NODE_VERSION ($NODE_BIN)"
      else
        add attention "Node" "$NODE_VERSION is too old; Node $NODE_MAJOR or newer is required"
      fi ;;
  esac
fi

NPM_BIN=$(command -v npm 2>/dev/null || true)
if [ -z "$NPM_BIN" ]; then
  add attention "npm" "Not installed; it comes bundled with Node"
elif [ "$IS_WSL" -eq 1 ] && is_windows_path "$NPM_BIN"; then
  add attention "npm" "Only Windows' copy is on PATH ($NPM_BIN); it cannot install this app's packages from Linux"
else
  NPM_VERSION=$(npm --version 2>/dev/null | head -1)
  if [ -n "$NPM_VERSION" ]; then
    add ready "npm" "$NPM_VERSION ($NPM_BIN)"
  else
    add attention "npm" "Found at $NPM_BIN but it did not run"
  fi
fi

# --- github cli ----------------------------------------------------------

# The GitHub CLI matters only when the user wants their app saved on GitHub.
# Downloading the template needs plain git and nothing else, so when GitHub was
# declined -- or has not been asked about yet -- a missing gh is a note.
if [ "$GITHUB" = yes ]; then GH_LEVEL=attention; else GH_LEVEL=note; fi

GH_AUTHENTICATED=0
GH_BIN=$(command -v gh 2>/dev/null || true)
if [ -z "$GH_BIN" ]; then
  if [ "$GITHUB" = yes ]; then
    add attention "GitHub CLI" "Not installed; needed to save your app on GitHub"
  else
    add note "GitHub CLI" "Not installed; only needed if you choose to save your app on GitHub"
  fi
elif [ "$IS_WSL" -eq 1 ] && is_windows_path "$GH_BIN"; then
  add "$GH_LEVEL" "GitHub CLI" "Only Windows' copy is on PATH ($GH_BIN); install it inside Linux"
else
  if gh auth status --hostname github.com >/dev/null 2>&1; then
    GH_AUTHENTICATED=1
    add ready "GitHub" "Signed in ($(gh --version 2>/dev/null | head -1))"
  elif [ "$GITHUB" = yes ]; then
    add attention "GitHub" "GitHub CLI is installed but not signed in"
  else
    add note "GitHub" "GitHub CLI is installed but not signed in; only needed to save your app on GitHub"
  fi
fi

# --- template access -----------------------------------------------------

# Two different questions. Downloading the template only needs an anonymous
# git read; being *marked as a template* matters solely to `gh repo create
# --template`, which is the GitHub-backed path.
if [ "$SKIP_NETWORK" -eq 1 ]; then
  add ready "Template access" "Skipped by request"
elif [ "$GITHUB" = yes ] && [ "$GH_AUTHENTICATED" -eq 1 ]; then
  IS_TEMPLATE=$(gh api "repos/$TEMPLATE_REPO" --jq '.is_template' 2>/dev/null || true)
  case "$IS_TEMPLATE" in
    true)  add ready "Template access" "$TEMPLATE_REPO is reachable and marked as a template" ;;
    false) add attention "Template access" "$TEMPLATE_REPO is reachable but is not marked as a template; tell a maintainer" ;;
    *)     add attention "Template access" "This GitHub account cannot reach $TEMPLATE_REPO; access must be granted by a maintainer" ;;
  esac
elif command -v git >/dev/null 2>&1; then
  if anonymous_ls_remote "https://github.com/$TEMPLATE_REPO"; then
    add ready "Template access" "$TEMPLATE_REPO can be downloaded; no GitHub account needed"
  elif git ls-remote --exit-code -h "https://github.com/$TEMPLATE_REPO" >/dev/null 2>&1; then
    # Works here only because this computer already holds GitHub credentials.
    # A student on a fresh machine would be stuck, so do not report it as fine.
    add attention "Template access" "$TEMPLATE_REPO is reachable only with your saved GitHub sign-in, so it is still private; a computer without a GitHub account could not download it. Tell a maintainer it needs to be public"
  else
    add attention "Template access" "$TEMPLATE_REPO could not be reached; check the internet connection, or sign in if the repository is still private"
  fi
else
  add attention "Template access" "Cannot be checked until Git is installed"
fi

# --- destination ---------------------------------------------------------

if [ -e "$DESTINATION" ]; then
  if [ ! -d "$DESTINATION" ]; then
    add attention "Destination" "$DESTINATION already exists and is not a folder; choose another path"
  elif [ -n "$(ls -A "$DESTINATION" 2>/dev/null)" ]; then
    add attention "Destination" "$DESTINATION already contains files; nothing will be changed there, so choose another path"
  else
    add ready "Destination" "$DESTINATION exists and is empty; it can be used"
  fi
else
  PARENT=$(dirname "$DESTINATION")
  while [ ! -e "$PARENT" ] && [ "$PARENT" != "/" ] && [ "$PARENT" != "." ]; do
    PARENT=$(dirname "$PARENT")
  done
  if [ -w "$PARENT" ]; then
    add ready "Destination" "$DESTINATION is new; $PARENT is writable"
  else
    add attention "Destination" "$DESTINATION cannot be created; $PARENT is not writable"
  fi

  FREE_KB=$(df -Pk "$PARENT" 2>/dev/null | awk 'NR==2 {print $4}')
  case "${FREE_KB:-}" in
    ''|*[!0-9]*) add attention "Disk space" "Free space near $PARENT could not be measured" ;;
    *)
      FREE_GB=$(awk -v k="$FREE_KB" 'BEGIN {printf "%.1f", k/1048576}')
      if [ "$FREE_KB" -ge 1048576 ]; then
        add ready "Disk space" "$FREE_GB GB available near the destination"
      else
        add attention "Disk space" "Only $FREE_GB GB available near the destination; about 1 GB is needed"
      fi ;;
  esac
fi

if [ "$IS_WSL" -eq 1 ] && is_windows_path "$DESTINATION"; then
  add attention "WSL location" "Choose a folder under the Linux home directory, not a mounted Windows drive"
fi

# --- report --------------------------------------------------------------

printf 'Hawk app preflight for %s\n\n' "$DESTINATION"
for LEVEL in ready note attention; do
  if ! grep -q "^$LEVEL|" "$TMP"; then continue; fi
  case "$LEVEL" in
    ready) printf 'Ready:\n' ;;
    note) printf 'Worth knowing:\n' ;;
    attention) printf 'Needs attention:\n' ;;
  esac
  while IFS='|' read -r level check detail; do
    [ "$level" = "$LEVEL" ] || continue
    case "$LEVEL" in
      ready) printf '  \342\234\223 %s: %s\n' "$check" "$detail" ;;
      note) printf '  - %s: %s\n' "$check" "$detail" ;;
      attention) printf '  ! %s: %s\n' "$check" "$detail" ;;
    esac
  done <"$TMP"
  printf '\n'
done

# Only "attention" blocks. A note is information the guide should pass on, not
# a reason to stop.
if grep -q '^attention|' "$TMP"; then exit 1; fi
exit 0
