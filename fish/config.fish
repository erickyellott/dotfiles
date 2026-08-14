set -gx VISUAL nvim
set -gx EDITOR $VISUAL
set -gx PYTHONDONTWRITEBYTECODE 1
set -gx HOMEBREW_CASK_OPTS --no-quarantine

if status is-interactive
    set -g fish_greeting "NO LOAFING!"

    alias todo "zed -n ~/Library/Mobile\ Documents/com~apple~CloudDocs/TODO.md"
    alias code "cd ~/Code"
    alias vs /usr/local/bin/code
    alias dc "docker compose"
    alias py ipython
    alias python python3
    alias pip pip3
    alias gb "git branch"
    alias nv neovide
    alias yolo "claude --dangerously-skip-permissions"
end

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init2.fish 2>/dev/null || :
