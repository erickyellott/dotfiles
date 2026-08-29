# The moon at tonight's real phase, drawn in braille. Replaces fish's stock
# greeting, which config.fish used to blank out with an empty $fish_greeting.
#
#   set -U moon_greeting 0    turn it off
#   set -U moon_aspect 2.4    cell height : width, if the moon looks oblong
#   set -U moon_color d54e53  any hex, or a fish color name
#
# Rendering costs ~100ms, which is too much to pay on every prompt, so the
# result is cached per day and per size and the greeting itself is just a cat.
function fish_greeting --description "The moon at its current phase"
    set -q moon_greeting; and test "$moon_greeting" = 0; and return

    set -l aspect 2.35
    set -q moon_aspect; and set aspect $moon_aspect

    # Width, padding and colour all live in `moon` itself, so a bare `moon`
    # and this greeting render identically. Only the aspect is passed through,
    # since that is the one thing worth tuning per machine.
    set -l dir $HOME/.cache/moon
    set -l cache $dir/(date +%F)-$aspect.txt

    if not test -s $cache
        command -q moon; or return
        command mkdir -p $dir
        # Write via a pid-suffixed temp so two shells starting at once cannot
        # read a half-written moon.
        if command moon --aspect $aspect >$cache.$fish_pid 2>/dev/null
            command mv -f $cache.$fish_pid $cache
        else
            command rm -f $cache.$fish_pid
            return
        end
        command find $dir -name '*.txt' -mtime +1 -delete 2>/dev/null
    end

    set -l color 7aa6da
    set -q moon_color; and set color $moon_color

    set_color $color
    command cat $cache
    set_color normal
end
