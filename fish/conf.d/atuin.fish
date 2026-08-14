if status is-interactive
    # Ctrl-R opens atuin's search; up arrow stays fish's native prefix search.
    atuin init fish --disable-up-arrow | source
end
