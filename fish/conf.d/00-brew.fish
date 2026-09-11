# Must live in conf.d (sourced before config.fish) so tools installed by
# Homebrew are on PATH for the other conf.d snippets, e.g. atuin.fish.
#
# Absent on Arch/Omarchy, where pacman installs the same tools to /usr/bin.
# Guarded rather than assumed, so this is a silent no-op there instead of an
# error on every shell start. Two prefixes: /opt/homebrew on macOS,
# /home/linuxbrew/.linuxbrew on Linux.
for brew_bin in /opt/homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew
    if test -x $brew_bin
        eval ($brew_bin shellenv)
        break
    end
end
set -e brew_bin
