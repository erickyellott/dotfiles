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

Atuin
----

Atuin replaces shell history with a searchable SQLite database. It is installed
by `brew bundle`.

Link the config and the fish integration:

```bash
mkdir -p ~/.config/atuin ~/.config/fish/conf.d
ln -sf "$HOME/Code/dotfiles/atuin/config.toml" "$HOME/.config/atuin/config.toml"
ln -sf "$HOME/Code/dotfiles/fish/conf.d/atuin.fish" \
  "$HOME/.config/fish/conf.d/atuin.fish"
```

Import existing shell history once, then open a new shell:

```bash
atuin import auto
```

The init runs with `--disable-up-arrow`, so `Ctrl+R` opens atuin's search and the
up arrow keeps fish's native prefix search. The init also binds bare `?` to
atuin's AI search.

`enter_accept = true` means `Enter` in the search UI runs the command
immediately; `Tab` puts it on the prompt to edit instead.

The history database in `~/.local/share/atuin` is not tracked — it is machine
state, and `key` in that directory is the sync encryption key. Back that key up
somewhere private if you ever enable sync; without it, synced history cannot be
decrypted on another machine.

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

Neovim
----

`neovim`, `neovide-app`, `gopls`, and `tree-sitter-cli` are installed by
`brew bundle`.

Link the config, the lockfile, the fallback theme, and Neovide's font settings:

```bash
mkdir -p "$HOME/.config/nvim/colors" "$HOME/.config/neovide"
ln -sf "$HOME/Code/dotfiles/nvim/init.lua" "$HOME/.config/nvim/init.lua"
ln -sf "$HOME/Code/dotfiles/nvim/lazy-lock.json" \
  "$HOME/.config/nvim/lazy-lock.json"
ln -sf "$HOME/Code/dotfiles/nvim/colors/Tomorrow-Night-Bright.vim" \
  "$HOME/.config/nvim/colors/Tomorrow-Night-Bright.vim"
ln -sf "$HOME/Code/dotfiles/neovide/config.toml" \
  "$HOME/.config/neovide/config.toml"
```

Plugins install on first launch. Then build the treesitter parsers:

```bash
nvim --headless -c 'lua require("nvim-treesitter").install({"go","gomod","gosum","gotmpl","lua","vim","vimdoc","query","bash","json","yaml","toml","markdown","markdown_inline","hcl","terraform","dockerfile","typescript","tsx","javascript","css","html","python","sql","diff","gitcommit"}):wait(600000)' -c 'qa'
```

Font size is set in `neovide/config.toml` and read at startup, so changing it
needs a full quit. To tune it live, `:set guifont=Monaco:h11`.

Ghostty
----

Ghostty reads `$XDG_CONFIG_HOME/ghostty/config` first and the macOS
Application Support path second, so the latter wins when both exist. Link that
one:

```bash
mkdir -p "$HOME/Library/Application Support/com.mitchellh.ghostty"
ln -sfn "$HOME/Code/dotfiles/ghostty/config" \
  "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
```

`Cmd+Shift+,` reloads the config, but some options — `macos-titlebar-style`
among them — only apply to new windows, so a full restart is sometimes needed.

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
