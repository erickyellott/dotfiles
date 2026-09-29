if status is-interactive
    # Redraw the prompt with the right prompt suppressed, then run the command,
    # so only the line being typed on carries the git info, not the backlog.
    #
    # --is-valid exits 0 valid, 1 invalid, 2 incomplete. Only 2 (open quote,
    # trailing pipe) skips the repaint, since enter just opens a continuation
    # line there instead of committing the command.
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
