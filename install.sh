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
#   ./install.sh --links-only symlinks only; skip packages, shell, apps

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Which machine this is. Untracked, so it never travels with the repo; absent
# means personal.
PROFILE_FILE="$HOME/.config/dotfiles/profile"
PROFILE=""

# Two separate axes. OS names the platform half of a config file
# ("ghostty/config.linux"), so it stays linux on every distro. PKG names who
# installs packages, which is its own question: Arch carries every formula the
# shared Brewfile lists, so Homebrew earns nothing there.
IS_ARCH=false
case "$(uname -s)" in
  Darwin)
    OS=macos
    PKG=brew
    BREW_PREFIX=/opt/homebrew
    ;;
  Linux)
    OS=linux
    PKG=brew
    BREW_PREFIX=/home/linuxbrew/.linuxbrew
    # Omarchy reports ID=omarchy with ID_LIKE=arch, so match on either.
    if [[ " $(. /etc/os-release 2>/dev/null; echo "${ID:-} ${ID_LIKE:-}") " == *" arch "* ]]; then
      IS_ARCH=true
      PKG=pacman
    fi
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

# On Omarchy, ~/.config/ghostty/config cannot be a symlink: `omarchy display
# text size` rewrites font-size in it with `sed -i`, which replaces the file
# and would silently detach ghostty from this repo (it already did once). So
# write a real file that owns nothing but the size and includes the repo's
# config. Omarchy keeps driving the size, and ghostty stays in step with foot.
#
# The size line belongs to Omarchy, so an existing one is carried forward
# rather than reset on every run.
write_ghostty_config() {
  local dest="$HOME/.config/ghostty/config" size=""

  if [[ -f "$dest" && ! -L "$dest" ]]; then
    size="$(sed -n 's/^font-size = \([0-9.]*\).*/\1/p' "$dest" | head -1)"
  fi
  # No size to carry forward (first run, or replacing the old symlink). Foot is
  # written by the same `omarchy display text size` command in the same units,
  # so it is the closest thing to the current system size. Omarchy's own
  # default is 9, which is what its 12px text size maps to.
  if [[ -z "$size" && -f "$HOME/.config/foot/foot.ini" ]]; then
    size="$(sed -n 's/.*:size=\([0-9.]*\).*/\1/p' "$HOME/.config/foot/foot.ini" | head -1)"
  fi
  [[ -n "$size" ]] || size=9

  local want
  want="$(
    printf '%s\n' \
      "# Written by install.sh, and deliberately not a symlink: \`omarchy display" \
      "# text size\` rewrites font-size below with sed -i, which would replace a" \
      "# link with a plain file and quietly detach ghostty from the dotfiles." \
      "# Omarchy owns the size; everything else lives in the repo." \
      "font-size = $size" \
      "" \
      "config-file = $DOTFILES/ghostty/config" \
      "config-file = $DOTFILES/ghostty/config.linux"
  )"

  if [[ -f "$dest" && ! -L "$dest" && "$(cat "$dest")" == "$want" ]]; then
    ok "$dest (font-size $size, Omarchy's)"
    return
  fi

  if $DRY_RUN; then
    printf '    %swould run:%s write %s (font-size %s)\n' \
      "$DIM" "$RESET" "$dest" "$size"
    CHANGES=$((CHANGES + 1))
    return
  fi

  if [[ -e "$dest" ]]; then
    mv "$dest" "$dest.bak.$STAMP"
    warn "backed up existing $dest -> $(basename "$dest").bak.$STAMP"
  fi
  mkdir -p "$(dirname "$dest")"
  printf '%s\n' "$want" >"$dest"
  changed "$dest (font-size $size, Omarchy's)"
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

  # Inbound SSH. Public keys only — nothing secret lives in this repo. sshd
  # rejects an authorized_keys that is group- or world-writable, and git
  # checks files out 644, so the symlink is fine.
  link ssh/authorized_keys "$HOME/.ssh/authorized_keys"

  # Linked but deliberately not enabled: running an agent unattended with
  # permissions bypassed is a per-machine decision, not a default.
  #   systemctl --user enable --now claude-remote-control
  link systemd/claude-remote-control.service \
    "$HOME/.config/systemd/user/claude-remote-control.service"

  link atuin/config.toml "$HOME/.config/atuin/config.toml"

  # On PATH via fish_add_path in config.fish; the fish greeting shells out to it.
  link bin/moon "$HOME/.local/bin/moon"

  # Pointed at by SUDO_ASKPASS in config.fish, so `sudo -A` can prompt for a
  # password without a terminal.
  link bin/askpass "$HOME/.local/bin/askpass"

  # Shared ghostty config plus the platform half it includes as `?platform`.
  # Arch is the exception; see write_ghostty_config.
  if $IS_ARCH; then
    write_ghostty_config
    unlink_file "$HOME/.config/ghostty/platform"
  else
    link ghostty/config "$HOME/.config/ghostty/config"
    link "ghostty/config.$OS" "$HOME/.config/ghostty/platform"
  fi
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

  # Omarchy. Only the files that actually differ from Omarchy's stock config —
  # tracking a stock copy just pins a default that upstream will move on from.
  # Themes and shell plugins are deliberately absent: they are git clones (169M
  # of them), reproduced with `omarchy theme install` / `omarchy plugin clone`.
  if $IS_ARCH; then
    link omarchy/xdg-terminals.list "$HOME/.config/xdg-terminals.list"
    link omarchy/hypr/bindings.lua "$HOME/.config/hypr/bindings.lua"
    link omarchy/hypr/monitors.lua "$HOME/.config/hypr/monitors.lua"
    link omarchy/shell.json "$HOME/.config/omarchy/shell.json"
    link omarchy/defaults/agent "$HOME/.config/omarchy/defaults/agent"
    # Bound in omarchy/hypr/bindings.lua; all three are hyprctl-only, so they
    # live under omarchy/ rather than bin/, which is for portable scripts.
    # They still install to ~/.local/bin so they land on PATH.
    link omarchy/bin/app-focus "$HOME/.local/bin/app-focus"
    link omarchy/bin/cycle-app-windows "$HOME/.local/bin/cycle-app-windows"
    link omarchy/bin/workspace-cycle "$HOME/.local/bin/workspace-cycle"
    unlink_file "$HOME/.local/bin/close-tab"
    unlink_file "$HOME/.local/bin/app-toggle"
  else
    unlink_file "$HOME/.config/xdg-terminals.list"
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

# ----------------------------------------------------------------- pacman ---

# Nothing to bootstrap the way Homebrew needs bootstrapping: Arch already has a
# package manager. yay when it is present, since it also reaches the AUR;
# pacman otherwise.
install_pacman() {
  phase "Packages"

  local list="$DOTFILES/pacman/packages"
  if [[ ! -f "$list" ]]; then
    warn "$list missing; skipped"
    return
  fi

  local pkgs=() pkg
  while read -r pkg; do
    pkgs+=("$pkg")
  done < <(sed 's/#.*//; s/[[:space:]]//g; /^$/d' "$list")

  if [[ ${#pkgs[@]} -eq 0 ]]; then
    warn "no packages listed; skipped"
    return
  fi

  # --needed makes this a no-op for anything already installed, which is most
  # of the list on Omarchy.
  if command -v yay >/dev/null 2>&1; then
    run yay -S --needed --noconfirm "${pkgs[@]}"
  else
    run sudo pacman -S --needed --noconfirm "${pkgs[@]}"
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

# ------------------------------------------------------------------ claude ---

# settings.json is not symlinked: it also holds machine-specific hooks and
# plugin state that must not travel with the repo. So merge in just the two
# keys this repo owns and leave every other key alone.
configure_claude() {
  phase "Claude settings"

  local settings="$HOME/.claude/settings.json"
  local theme="custom:tomorrow-night-bright"
  local cmd="bash ~/.claude/statusline-command.sh"

  if ! command -v jq >/dev/null 2>&1; then
    warn "jq unavailable; set theme, statusLine and remoteControlAtStartup by hand"
    return
  fi

  if [[ -e "$settings" ]] && ! jq -e . "$settings" >/dev/null 2>&1; then
    warn "$settings is not valid JSON; left alone"
    return
  fi

  local current=""
  [[ -f "$settings" ]] && current="$(cat "$settings")"
  [[ -n "$current" ]] || current='{}'

  local merged
  # remoteControlAtStartup also spares the systemd unit from answering the
  # "Enable Remote Control?" prompt on stdin.
  merged="$(printf '%s' "$current" | jq --arg theme "$theme" --arg cmd "$cmd" \
    '.theme = $theme
     | .statusLine = { type: "command", command: $cmd }
     | .remoteControlAtStartup = true')" || {
    warn "could not merge $settings; left alone"
    return
  }

  if [[ "$(printf '%s' "$current" | jq -S .)" == "$(printf '%s' "$merged" | jq -S .)" ]]; then
    ok "claude settings already set"
    return
  fi

  if $DRY_RUN; then
    printf '    %swould run:%s merge theme and statusLine into %s\n' \
      "$DIM" "$RESET" "$settings"
    CHANGES=$((CHANGES + 1))
    return
  fi

  # cp, not the mv the link helper uses: this file is edited in place, so the
  # original has to stay where it is.
  if [[ -f "$settings" ]]; then
    cp "$settings" "$settings.bak.$STAMP"
    warn "backed up $settings -> $(basename "$settings").bak.$STAMP"
  fi
  mkdir -p "$(dirname "$settings")"
  printf '%s\n' "$merged" >"$settings"
  changed "claude settings -> $settings"
}

print_manual() {
  phase "Still to do by hand"
  cat <<'MANUAL'
    Alfred   - Preferences > load from iCloud
    atuin    - `atuin import auto` once, then open a new shell
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
    # Packages first: everything after it depends on something they install.
    if [[ "$PKG" == pacman ]]; then
      install_pacman
    else
      install_homebrew
    fi
    link_all
    setup_shell
    if [[ "$OS" == macos ]]; then
      install_hermes
      macos_defaults
    fi
    install_parsers
    configure_claude
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
