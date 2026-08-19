# Wrapper so `nuonctl` runs from source (NUONCTL_LOCAL) instead of the stale
# binary in ~/bin. Matches the zsh function in ../../zshrc.
function nuonctl --description 'run nuonctl via mono/run-nuonctl.sh'
    $NUON_ROOT/mono/run-nuonctl.sh $argv
end
