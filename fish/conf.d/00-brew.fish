# Must live in conf.d (sourced before config.fish) so Homebrew tools are on
# PATH for other conf.d snippets, e.g. atuin.fish.
#
# No-op on Arch/Omarchy, where pacman installs the same tools to /usr/bin.
# Two prefixes: /opt/homebrew on macOS, /home/linuxbrew/.linuxbrew on Linux.
for brew_bin in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew
    if test -x $brew_bin
        eval ($brew_bin shellenv)
        break
    end
end
set -e brew_bin
