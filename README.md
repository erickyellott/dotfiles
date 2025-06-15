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
git clone git@github.com:boxy-robot/dotfiles.git
```

Link gitconfigs:

```bash
ln -s "$HOME/Code/dotfiles/gitconfig" "$HOME/.gitconfig"
ln -s "$HOME/Code/dotfiles/gitignore" "$HOME/.gitignore"
```

Install prezto:

```bash
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done
```

Link zshrc:

```bash
ln -sf "$HOME/Code/dotfiles/zshrc" "$HOME/.zshrc"
```

Silence last login terminal message:

```bash
touch ~/.hushlogin
```


iTerm
----

Open "Tomorrow Night Bright.itermcolors"
Tell iTerm to load your preferences from iCloud.

![iTerm](img/iterm-install.png?raw=true)


Visual Studio Code
----

Install cli command by searching for "Install code" from the command palette.

![vscode](img/vscode-install.png?raw=true)


Login to github:
![vscode](img/vscode-signin.png?raw=true)


Alfred
----

Tell alfred to load your preferences from iCloud.

![alfred](img/alfred-install.png?raw=true)


Rectangle
----

Tell Rectangle to sync via iCloud.

![rectangle](img/rectangle-install.png?raw=true)


Disable macos screenshot thumbnails
----

```bash
defaults write com.apple.screencapture show-thumbnail -bool NO
killall SystemUIServer
```
