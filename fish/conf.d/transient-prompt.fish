if status is-interactive
    # Redraw the prompt with the right prompt suppressed, then run the command.
    # The repaint emits an erase-to-end-of-screen, so the git info is wiped off
    # the line before it scrolls into the backlog: past commands copy clean, and
    # only the line I'm typing on carries the branch.
    #
    # --is-valid exits 0 valid, 1 invalid, 2 incomplete. Only 2 (open quote,
    # trailing pipe) stays put: enter opens a continuation line there, so the
    # prompt isn't going anywhere yet. 1 still commits the line to scrollback
    # -- it just prints a syntax error -- so it gets the same treatment as 0.
    function _transient_execute
        commandline --is-valid
        if test $status -ne 2
            set -g _fish_transient 1
            commandline -f repaint
        end
        commandline -f execute
    end

    bind enter _transient_execute
end
