Erick's dotfiles
====

iTerm
----

![iTerm](img/iterm.png?raw=true)

vim
----

![iTerm](img/vim.png?raw=true)

tig
----

![iTerm](img/tig.png?raw=true)

Installation
====

Homebrew
---

Install homebrew and run brew bundle:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew bundle
```

Shell
----

Create ssh key:

```bash
ssh-keygen -t ed25519 -C "erick.yellott@gmail.com"
echo "AddKeysToAgent yes" >> ~/.ssh/config
echo "IdentityFile ~/.ssh/id_ed25519" >> ~/.ssh/config
ssh-add
```

Add the key to GitHub: https://github.com/settings/keys

Make Code directory:

```bash
mkdir -p ~/Code
```

Clone this repo:

```
cd ~/Code
git clone git@github.com:erickyellott/dotfiles.git
```

Link gitconfigs:

```bash
ln -s "$HOME/Code/dotfiles/gitconfig" "$HOME/.gitconfig"
ln -s "$HOME/Code/dotfiles/gitignore" "$HOME/.gitignore"
```

Silence last login terminal message:

```bash
touch ~/.hushlogin
```

Fish
----

Fish is installed by `brew bundle`. Make it the login shell:

```bash
echo /opt/homebrew/bin/fish | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/fish
```

Link the config, prompt, and theme:

```bash
mkdir -p ~/.config/fish/conf.d ~/.config/fish/functions
ln -sf "$HOME/Code/dotfiles/fish/config.fish" "$HOME/.config/fish/config.fish"
ln -sf "$HOME/Code/dotfiles/fish/conf.d/fish_frozen_theme.fish" \
  "$HOME/.config/fish/conf.d/fish_frozen_theme.fish"
ln -sf "$HOME/Code/dotfiles/fish/functions/fish_prompt.fish" \
  "$HOME/.config/fish/functions/fish_prompt.fish"
ln -sf "$HOME/Code/dotfiles/fish/functions/fish_right_prompt.fish" \
  "$HOME/.config/fish/functions/fish_right_prompt.fish"
```

`config.fish` runs `eval (/opt/homebrew/bin/brew shellenv)` — on Apple Silicon
Homebrew lives in `/opt/homebrew`, which is not on the default `PATH`.

`~/.config/fish/fish_variables` is not tracked; fish rewrites it whenever a
universal variable changes. Anything worth keeping goes in `config.fish` instead
— a global there shadows a universal of the same name.

Claude
----

Link the global instructions and the Tomorrow Night Bright theme:

```bash
mkdir -p "$HOME/.claude/themes"
ln -sf "$HOME/Code/dotfiles/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
ln -sf "$HOME/Code/dotfiles/claude/tomorrow-night-bright.json" \
  "$HOME/.claude/themes/tomorrow-night-bright.json"
```

Then pick the theme with `/config`, or set it directly in
`~/.claude/settings.json`:

```json
{ "theme": "custom:tomorrow-night-bright" }
```

`settings.json` itself is not symlinked — it holds machine-specific hooks and
plugin state.

iTerm
----

Open "Tomorrow Night Bright.itermcolors"

Tell iTerm to load your preferences from iCloud.

![iTerm](img/iterm-install.png?raw=true)

Alfred
----

Tell alfred to load your preferences from iCloud.

![alfred](img/alfred-install.png?raw=true)

Disable macos screenshot thumbnails
----

```bash
defaults write com.apple.screencapture show-thumbnail -bool NO
killall SystemUIServer
```
