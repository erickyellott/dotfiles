# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

alias todo="zed -n ~/Library/Mobile\ Documents/com~apple~CloudDocs/TODO.md"
alias code="cd ~/Code"
alias vs="/usr/local/bin/code"
alias dc="docker compose"
alias py=ipython
alias python="python3"
alias pip="pip3"
alias git="noglob git"
alias nuke="find . | grep -E \"(/__pycache__$|\.pyc$|\.pyo$|\.coverage$|coverage.xml)\" | xargs rm -rf"

export VISUAL=vim
export EDITOR="$VISUAL"
export PYTHONDONTWRITEBYTECODE=1
