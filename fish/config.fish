set -gx VISUAL nvim
set -gx EDITOR $VISUAL
set -gx PYTHONDONTWRITEBYTECODE 1
set -gx HOMEBREW_CASK_OPTS --no-quarantine
set -gx ENABLE_PROMPT_CACHING_1H 1

# Where install.sh links `moon`, used by the greeting in functions/.
fish_add_path -g $HOME/.local/bin

if status is-interactive
    # The greeting is functions/fish_greeting.fish, which overrides fish's
    # stock one outright, so $fish_greeting no longer needs blanking here.

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
