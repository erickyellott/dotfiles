#!/usr/bin/env bash
#
# Idempotent setup for this dotfiles repo.
#
# Safe to re-run at any time: anything already correct is left untouched, and
# anything real that is in the way is backed up before being replaced. Bash
# rather than fish, because it has to run before fish is installed.
#
#   ./install.sh              full setup
#   ./install.sh --dry-run    print what would happen, change nothing
#   ./install.sh --links-only symlinks only; skip brew, shell, apps

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Which machine this is. Untracked, so it never travels with the repo; absent
# means personal.
PROFILE_FILE="$HOME/.config/dotfiles/profile"
PROFILE=""

case "$(uname -s)" in
  Darwin)
    OS=macos
    BREW_PREFIX=/opt/homebrew
    ;;
  Linux)
    OS=linux
    BREW_PREFIX=/home/linuxbrew/.linuxbrew
    ;;
  *) printf 'unsupported platform: %s\n' "$(uname -s)" >&2; exit 1 ;;
esac
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY_RUN=false
LINKS_ONLY=false
CHANGES=0

# ---------------------------------------------------------------- output ---

if [[ -t 1 ]]; then
  BOLD=$'\033[1m' DIM=$'\033[2m' RED=$'\033[31m' GREEN=$'\033[32m'
  YELLOW=$'\033[33m' RESET=$'\033[0m'
else
  BOLD='' DIM='' RED='' GREEN='' YELLOW='' RESET=''
fi

phase() { printf '\n%s==> %s%s\n' "$BOLD" "$1" "$RESET"; }
ok() { printf '    %s%s%s\n' "$DIM" "$1" "$RESET"; }
warn() { printf '    %s!%s %s\n' "$YELLOW" "$RESET" "$1"; }
die() {
  printf '%serror:%s %s\n' "$RED" "$RESET" "$1" >&2
  exit 1
}

changed() {
  printf '    %s+%s %s\n' "$GREEN" "$RESET" "$1"
  CHANGES=$((CHANGES + 1))
}

# Run a command, or describe it under --dry-run.
run() {
  if $DRY_RUN; then
    printf '    %swould run:%s %s\n' "$DIM" "$RESET" "$*"
  else
    "$@"
  fi
}

usage() {
  sed -n '3,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# ---------------------------------------------------------------- profile ---

resolve_profile() {
  if [[ -r "$PROFILE_FILE" ]]; then
    PROFILE="$(tr -d '[:space:]' <"$PROFILE_FILE")"
  fi

  if [[ -z "$PROFILE" ]]; then
    if [[ -t 0 ]]; then
      local reply
      while [[ -z "$PROFILE" ]]; do
        printf 'Which machine is this? [%spersonal%s/work] ' "$BOLD" "$RESET"
        read -r reply || reply=personal
        # tr, not ${reply,,}: macOS ships bash 3.2.
        reply="$(printf '%s' "${reply:-personal}" | tr '[:upper:]' '[:lower:]')"
        case "$reply" in
          work | personal) PROFILE="$reply" ;;
          *) printf '  answer work or personal\n' ;;
        esac
      done
      if $DRY_RUN; then
        printf '    %swould run:%s write %s to %s\n' \
          "$DIM" "$RESET" "$PROFILE" "$PROFILE_FILE"
      else
        mkdir -p "$(dirname "$PROFILE_FILE")"
        printf '%s\n' "$PROFILE" >"$PROFILE_FILE"
        printf '    %ssaved to %s%s\n' "$DIM" "$PROFILE_FILE" "$RESET"
      fi
    else
      # Piped or run from cron: never block waiting on an answer.
      PROFILE=personal
      warn "no $PROFILE_FILE and no terminal to ask; assuming personal"
    fi
  fi

  case "$PROFILE" in
    work | personal) ;;
    *) die "unknown profile '$PROFILE' in $PROFILE_FILE (want: work | personal)" ;;
  esac
}

# ------------------------------------------------------------------ links ---

# link <repo-relative-source> <absolute-destination>
#
# `ln -sfn`, not `ln -sf`: ~/.config/nvim is a symlink to a *directory*, and
# without -n the second run would create the link inside it (~/.config/nvim/nvim)
# rather than replacing it.
link() {
  local src="$DOTFILES/$1" dest="$2" target

  [[ -e "$src" ]] || die "missing source: $src"

  if [[ -L "$dest" ]]; then
    target="$(readlink "$dest")"
    if [[ "$target" == "$src" ]]; then
      ok "$dest"
      return
    fi
    if [[ "$target" == "$DOTFILES"/* || ! -e "$dest" ]]; then
      # Already ours, just pointing at an old path — or dangling because the
      # repo moved a file. Replace it rather than leaving .bak litter behind
      # every time the repo is reorganized.
      run rm -f "$dest"
    else
      run mv "$dest" "$dest.bak.$STAMP"
      warn "backed up existing $dest -> $(basename "$dest").bak.$STAMP"
    fi
  elif [[ -e "$dest" ]]; then
    run mv "$dest" "$dest.bak.$STAMP"
    warn "backed up existing $dest -> $(basename "$dest").bak.$STAMP"
  fi

  run mkdir -p "$(dirname "$dest")"
  run ln -sfn "$src" "$dest"
  changed "$dest"
}

# Link every file in a repo directory, so adding one to the repo deploys it on
# the next run. Naming files individually is what let three of them silently go
# unlinked on this machine.
link_dir() {
  local subdir="$1" dest_dir="$2" path name
  [[ -d "$DOTFILES/$subdir" ]] || return 0
  for path in "$DOTFILES/$subdir"/*; do
    [[ -f "$path" ]] || continue
    name="$(basename "$path")"
    link "$subdir/$name" "$dest_dir/$name"
  done
}

# Remove links this repo owns that the active profile no longer wants, so
# switching profiles cleans up after itself instead of leaving stale files.
# Match on "points into this repo" rather than the exact path: once a file moves
# in the repo the old link dangles and an exact match never fires.
unlink_file() {
  local dest="$1"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$DOTFILES"/* ]]; then
    run rm -f "$dest"
    changed "removed $dest (not in the $PROFILE profile)"
  fi
}

unlink_dir() {
  local subdir="$1" dest_dir="$2" path
  [[ -d "$DOTFILES/$subdir" ]] || return 0
  for path in "$DOTFILES/$subdir"/*; do
    [[ -f "$path" ]] || continue
    unlink_file "$dest_dir/$(basename "$path")"
  done
}

link_all() {
  phase "Symlinks"

  link git/gitconfig "$HOME/.gitconfig"
  link git/gitignore "$HOME/.gitignore"
  # Personal identity lives in gitconfig itself; only work overrides it.
  if [[ "$PROFILE" == work ]]; then
    link git/gitconfig.work "$HOME/.gitconfig.local"
  else
    unlink_file "$HOME/.gitconfig.local"
  fi

  # Prune first: anything the shared or active-profile pass still wants gets
  # re-linked immediately below, so an over-eager removal repairs itself.
  local other
  for other in work personal; do
    [[ "$other" == "$PROFILE" ]] && continue
    unlink_dir "fish/$other/conf.d" "$HOME/.config/fish/conf.d"
    unlink_dir "fish/$other/functions" "$HOME/.config/fish/functions"
  done

  link fish/config.fish "$HOME/.config/fish/config.fish"
  link_dir fish/conf.d "$HOME/.config/fish/conf.d"
  link_dir fish/functions "$HOME/.config/fish/functions"
  link_dir "fish/$PROFILE/conf.d" "$HOME/.config/fish/conf.d"
  link_dir "fish/$PROFILE/functions" "$HOME/.config/fish/functions"

  link atuin/config.toml "$HOME/.config/atuin/config.toml"

  # On PATH via fish_add_path in config.fish; the fish greeting shells out to it.
  link bin/moon "$HOME/.local/bin/moon"

  # Shared ghostty config plus the platform half it includes as `?platform`.
  link ghostty/config "$HOME/.config/ghostty/config"
  link "ghostty/config.$OS" "$HOME/.config/ghostty/platform"
  link neovide/config.toml "$HOME/.config/neovide/config.toml"
  link k9s/views.yaml "$HOME/.config/k9s/views.yaml"
  link hermes/default.json "$HOME/.config/hermes/default.json"

  # The whole directory, so new plugin files need no change here.
  link nvim "$HOME/.config/nvim"

  link_dir zed "$HOME/.config/zed"

  link claude/CLAUDE.md "$HOME/.claude/CLAUDE.md"
  link claude/tomorrow-night-bright.json \
    "$HOME/.claude/themes/tomorrow-night-bright.json"
  link claude/statusline-command.sh "$HOME/.claude/statusline-command.sh"

  if [[ "$OS" == linux ]]; then
    link cosmic/shortcuts \
      "$HOME/.config/cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom"
  fi

  if [[ "$OS" == macos ]]; then
    # Silences the "last login" banner. Not a symlink; it just has to exist.
    if [[ -e "$HOME/.hushlogin" ]]; then
      ok "$HOME/.hushlogin"
    else
      run touch "$HOME/.hushlogin"
      changed "$HOME/.hushlogin"
    fi
  fi
}

# --------------------------------------------------------------- homebrew ---

# Homebrew refuses to load formulae from third-party taps until they are
# trusted. Trust whatever the Brewfiles declare, so `brew bundle` can run
# unattended.
trust_taps() {
  brew trust --help >/dev/null 2>&1 || return 0

  local file tap
  for file in "$@"; do
    [[ -f "$file" ]] || continue
    while read -r tap; do
      run brew trust --tap "$tap"
    done < <(sed -n 's/^tap "\([^"]*\)".*/\1/p' "$file")
  done
}

install_homebrew() {
  phase "Homebrew"

  if command -v brew >/dev/null 2>&1; then
    ok "homebrew present"
  elif $DRY_RUN; then
    printf '    %swould run:%s homebrew installer\n' "$DIM" "$RESET"
  else
    /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    changed "installed homebrew"
  fi

  # A fresh install is not on PATH yet in this same process.
  if [[ -x "$BREW_PREFIX/bin/brew" ]]; then
    eval "$("$BREW_PREFIX/bin/brew" shellenv)"
  fi

  if ! command -v brew >/dev/null 2>&1; then
    warn "brew unavailable; skipped Brewfiles"
    return
  fi

  trust_taps "$DOTFILES/brew/Brewfile" "$DOTFILES/brew/Brewfile.$OS"

  run brew bundle --file="$DOTFILES/brew/Brewfile"

  # Casks are macOS-only; `brew bundle` on Linux errors on a cask line.
  if [[ -f "$DOTFILES/brew/Brewfile.$OS" ]]; then
    run brew bundle --file="$DOTFILES/brew/Brewfile.$OS"
  fi
}

# ------------------------------------------------------------ login shell ---

setup_shell() {
  phase "Login shell"

  local fish
  fish="$(command -v fish 2>/dev/null || true)"
  if [[ -z "$fish" ]]; then
    warn "fish not installed; skipping"
    return
  fi

  if grep -qxF "$fish" /etc/shells; then
    ok "$fish in /etc/shells"
  elif $DRY_RUN; then
    printf '    %swould run:%s echo %s | sudo tee -a /etc/shells\n' \
      "$DIM" "$RESET" "$fish"
  else
    echo "$fish" | sudo tee -a /etc/shells >/dev/null
    changed "added $fish to /etc/shells"
  fi

  # Not $SHELL: that is whatever is running, not the configured login shell, so
  # it reports stale after a chsh until the next login.
  local current
  if [[ "$OS" == macos ]]; then
    current="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
  else
    current="$(getent passwd "$USER" | cut -d: -f7)"
  fi
  if [[ "$current" == "$fish" ]]; then
    ok "login shell is fish"
  else
    run chsh -s "$fish"
    changed "login shell -> $fish"
  fi
}

# ----------------------------------------------------------------- hermes ---

install_hermes() {
  phase "Hermes"

  local api="https://api.github.com/repos/erickyellott/hermes/releases/latest"
  local json latest url installed=""

  json="$(curl -fsSL "$api" 2>/dev/null)" || {
    warn "could not reach GitHub; skipping"
    return
  }

  latest="$(printf '%s' "$json" |
    sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/p' | head -1)"
  [[ -n "$latest" ]] || {
    warn "could not parse latest release; skipping"
    return
  }

  if [[ -d /Applications/Hermes.app ]]; then
    installed="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' \
      /Applications/Hermes.app/Contents/Info.plist 2>/dev/null || true)"
  fi

  if [[ "$installed" == "$latest" ]]; then
    ok "Hermes $installed"
    return
  fi

  url="$(printf '%s' "$json" |
    sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\.zip\)".*/\1/p' | head -1)"
  [[ -n "$url" ]] || {
    warn "no .zip asset on $latest; skipping"
    return
  }

  if $DRY_RUN; then
    printf '    %swould run:%s install Hermes %s (have %s)\n' \
      "$DIM" "$RESET" "$latest" "${installed:-none}"
    CHANGES=$((CHANGES + 1))
    return
  fi

  local tmp
  tmp="$(mktemp -d)"
  # ditto, not unzip: it preserves the bundle's resource forks and signature.
  curl -fsSL -o "$tmp/hermes.zip" "$url"
  ditto -xk "$tmp/hermes.zip" "$tmp/unpacked"

  local app
  app="$(find "$tmp/unpacked" -maxdepth 2 -name 'Hermes.app' -print -quit)"
  if [[ -z "$app" ]]; then
    rm -rf "$tmp"
    warn "no Hermes.app inside the release zip; skipping"
    return
  fi

  rm -rf /Applications/Hermes.app
  ditto "$app" /Applications/Hermes.app
  xattr -dr com.apple.quarantine /Applications/Hermes.app 2>/dev/null || true
  rm -rf "$tmp"
  changed "Hermes ${installed:-none} -> $latest"
}

# --------------------------------------------------------- macos defaults ---

macos_defaults() {
  phase "macOS defaults"

  local current
  current="$(defaults read com.apple.screencapture show-thumbnail 2>/dev/null || echo 1)"
  if [[ "$current" == "0" ]]; then
    ok "screenshot thumbnails off"
  else
    run defaults write com.apple.screencapture show-thumbnail -bool NO
    if ! $DRY_RUN; then killall SystemUIServer 2>/dev/null || true; fi
    changed "disabled screenshot thumbnails"
  fi
}

# ------------------------------------------------------ treesitter parsers ---

install_parsers() {
  phase "Treesitter parsers"

  if ! command -v nvim >/dev/null 2>&1; then
    warn "nvim not installed; skipping"
    return
  fi

  if $DRY_RUN; then
    printf '    %swould run:%s build parsers from astrocore ensure_installed\n' \
      "$DIM" "$RESET"
    return
  fi

  # The list lives in nvim/lua/plugins/treesitter.lua; read it back rather than
  # duplicating it here. Blocks until every parser is built.
  ok "building (several minutes on a cold cache)"
  nvim --headless \
    -c "lua require('nvim-treesitter').install(require('astrocore').config.treesitter.ensure_installed):wait(900000)" \
    -c "qa" >/dev/null 2>&1 || warn "parser build reported an error"
  ok "parsers built"
}

# ----------------------------------------------------------------- manual ---

print_manual() {
  phase "Still to do by hand"
  cat <<'MANUAL'
    Alfred   - Preferences > load from iCloud
    atuin    - `atuin import auto` once, then open a new shell
    Claude   - add to ~/.claude/settings.json (not symlinked; it holds
               machine-specific hooks and plugin state):
                 "theme": "custom:tomorrow-night-bright"
                 "statusLine": { "type": "command",
                                 "command": "bash ~/.claude/statusline-command.sh" }
MANUAL
}

# ------------------------------------------------------------------- main ---

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=true ;;
      --links-only) LINKS_ONLY=true ;;
      -h | --help)
        usage
        exit 0
        ;;
      *) die "unknown option: $1" ;;
    esac
    shift
  done

  [[ -d "$DOTFILES/.git" ]] || die "$DOTFILES does not look like the dotfiles repo"

  if $DRY_RUN; then
    printf '%sdry run — nothing will be changed%s\n' "$YELLOW" "$RESET"
  fi

  resolve_profile
  printf '%s%s / %s profile%s\n' "$DIM" "$OS" "$PROFILE" "$RESET"

  if $LINKS_ONLY; then
    link_all
  else
    # Homebrew first: everything after it depends on something brew installs.
    install_homebrew
    link_all
    setup_shell
    if [[ "$OS" == macos ]]; then
      install_hermes
      macos_defaults
    fi
    install_parsers
    print_manual
  fi

  printf '\n'
  if [[ $CHANGES -eq 0 ]]; then
    printf '%sEverything already up to date.%s\n' "$GREEN" "$RESET"
  elif $DRY_RUN; then
    printf '%s%d change(s) would be made.%s\n' "$YELLOW" "$CHANGES" "$RESET"
  else
    printf '%s%d change(s) made.%s\n' "$GREEN" "$CHANGES" "$RESET"
  fi
}

main "$@"
