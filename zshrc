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
alias gb="git branch"

export VISUAL=vim
export EDITOR="$VISUAL"
export PYTHONDONTWRITEBYTECODE=1
export HOMEBREW_CASK_OPTS="--no-quarantine"

# Nuon
export PATH="$HOME/bin:$HOME/go/bin:$PATH"
export AWS_PROFILE="stage.NuonAdmin"
export AWS_REGION="us-west-2"
export NUON_PREVIEW=true
export NUON_ROOT="/Users/yellott/nuonco"
export NUONCTL_LOCAL=true
export DD_SITE="us5.datadoghq.com"
export USE_LOCAL_RUNNERS=false

nuonctl () {
        ~/nuonco/mono/run-nuonctl.sh "$@"
}

alias nuonstage="nuon -f ~/.stage.yml"
