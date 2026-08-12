function nuke --description "Remove python bytecode and coverage artifacts"
    find . | grep -E '(/__pycache__$|\.pyc$|\.pyo$|\.coverage$|coverage.xml)' | xargs rm -rf
end
