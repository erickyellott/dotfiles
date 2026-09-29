Erick's dotfiles
====

vim
----

![vim](img/vim.png?raw=true)

tig
----

![tig](img/tig.png?raw=true)

Runs on macOS and Pop!_OS (COSMIC). Platform-specific pieces — casks, Hermes,
macOS defaults, COSMIC shortcuts — are selected automatically.

What this sets up
====

- **Ghostty** — terminal, Monaco on a Tomorrow Night Bright palette
- **fish** — login shell, custom prompt, atuin history search on `Ctrl+R`
- **Neovim + Neovide** — AstroNvim-based config, macOS-style Cmd/Option
  keybindings, treesitter parsers prebuilt
- **Zed** — settings and keymap
- **Claude Code** — global instructions, theme, status line
- **Hermes** — window manager, installed from its GitHub releases
- **k9s**, **git** — views, gitconfig, global gitignore

Homebrew packages are split: `brew/Brewfile` is shared, `brew/Brewfile.macos`
holds the casks (Linuxbrew has no cask support), and `brew/Brewfile.linux` is
for Pop!_OS additions. On Pop!_OS the script installs CLI tools only — GUI apps
come from apt, flatpak, or the Pop!_Shop.

Before you run it
====

On macOS, install the Xcode command line tools:

```bash
xcode-select --install
```

On Pop!_OS, install the Homebrew prerequisites:

```bash
sudo apt install build-essential procps curl file git
```

Create an SSH key and add it to GitHub at https://github.com/settings/keys:

```bash
ssh-keygen -t ed25519 -C "erick.yellott@gmail.com"
ssh-add
```

`AddKeysToAgent` and `IdentityFile` no longer go in by hand: they live in
`ssh/config`, which `install.sh` symlinks over `~/.ssh/config` (backing up
anything already there). Cloning below works without it, since ssh tries
`~/.ssh/id_ed25519` by default anyway.

Clone the repo:

```bash
mkdir -p ~/Code
git clone git@github.com:erickyellott/dotfiles.git ~/Code/dotfiles
```

Machine profile
====

Work and personal machines differ in two places: the git email, and the Nuon
fish config. Which one a machine is comes from an untracked file:

```bash
mkdir -p ~/.config/dotfiles
echo work > ~/.config/dotfiles/profile   # or: personal
```

Absent, it defaults to `personal` — which is just the committed config, since
the personal email lives in `git/gitconfig` directly. On `work` the script links
`git/gitconfig.work` over it and adds the `fish/work/` files; switching back to
`personal` removes both again.

Run it
====

```bash
cd ~/Code/dotfiles
./install.sh
```

It installs Homebrew and the Brewfiles for the current platform, symlinks every
config, makes fish the login shell, and builds the treesitter parsers. On macOS
it also installs Hermes and sets a few system defaults. It is safe to
re-run at any time — anything already correct is left alone, and anything real
in the way is backed up to `<name>.bak.<timestamp>` first.

```bash
./install.sh --dry-run      # print what would change, change nothing
./install.sh --links-only   # just the symlinks; skip brew, shell, apps
```

Still to do by hand
====

- **Alfred** — load preferences from iCloud

  ![alfred](img/alfred-install.png?raw=true)

- **atuin** — import existing shell history once, then open a new shell:

  ```bash
  atuin import auto
  ```

- **Claude Code Remote Control** — lets the phone app start *new* sessions on
  a machine. `remoteControlAtStartup` alone only exposes sessions a terminal is
  already running; starting fresh ones needs a `claude remote-control` host
  process alive full time. `install.sh` links the service but never loads it —
  an always-on agent running with `--permission-mode bypassPermissions` is a
  per-machine call, not a default. Turn it on with:

  ```bash
  # linux
  systemctl --user enable --now claude-remote-control

  # macos
  launchctl bootstrap gui/$UID \
    ~/Library/LaunchAgents/com.erickyellott.claude-remote-control.plist
  ```

  Homebrew is no help here: `claude-code` is a cask, casks cannot declare a
  `service` block, and `brew services` only reads formulae — hence the plist.
  On a laptop the Mac dropping off when it sleeps is expected; `caffeine` (in
  `brew/Brewfile.macos`) is the lever for that. Logs are `journalctl --user -u
  claude-remote-control` on Linux and `~/Library/Logs/claude-remote-control.log`
  on macOS.

- **Claude Code** — add to `~/.claude/settings.json`, which is not symlinked
  because it holds machine-specific hooks and plugin state:

  ```json
  {
    "theme": "custom:tomorrow-night-bright",
    "statusLine": {
      "type": "command",
      "command": "bash ~/.claude/statusline-command.sh"
    }
  }
  ```

  The status line shows the model, directory, and a filling bar for context
  and quota usage with the percentage printed inside it (green under 50%,
  yellow to 80%, red above). API-key sessions have no quota, so they show
  accrued cost instead.
