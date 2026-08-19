# Nuon -- mirrors the "# Nuon" block in ../../zshrc.
fish_add_path -gp $HOME/bin $HOME/go/bin

set -gx AWS_PROFILE stage.NuonAdmin
set -gx AWS_REGION us-west-2
set -gx DD_SITE us5.datadoghq.com
set -gx NUON_PREVIEW true
set -gx NUON_ROOT $HOME/nuonco
set -gx NUONCTL_LOCAL true
set -gx USE_LOCAL_RUNNERS false

if status is-interactive
    alias nuonstage "nuon -f ~/.stage.yml"
end
