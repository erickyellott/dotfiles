-- Shared by both front-ends: nvim inside iTerm2, and Neovide.

vim.g.mapleader = " "

-- Bootstrap lazy.nvim (clones itself on first launch).
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- 24-bit color. The colorscheme then emits exact hex and no longer depends on
-- the terminal's 16-color palette, so nvim looks identical in iTerm2 and Neovide.
vim.o.termguicolors = true
vim.opt.mouse = 'a'

-- Hybrid numbering: absolute on the cursor line, relative elsewhere, so motion
-- counts like d3j can be read straight off the gutter.
vim.opt.number = true
vim.opt.relativenumber = true

-- Reserve the sign column so the text does not shift sideways when gopls
-- diagnostics appear and disappear.
vim.opt.signcolumn = "yes"

-- Show whitespace. These glyphs are all Latin-1, which Monaco covers in full.
vim.opt.list = true
vim.opt.listchars = { tab = "· ", eol = "¬", trail = "·", nbsp = "¤" }
vim.keymap.set("n", "<Leader>w", "<cmd>set list!<cr>", { desc = "Toggle whitespace" })

-- New splits open right and below, matching modern editors.
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.keymap.set("n", "<Leader>d", "<cmd>vnew<cr>", { desc = "Split window vertically" })
vim.keymap.set("n", "<Leader>D", "<cmd>new<cr>", { desc = "Split window horizontally" })
vim.keymap.set("n", "<Leader>h", "<C-w>h", { desc = "Focus left pane" })
vim.keymap.set("n", "<Leader>j", "<C-w>j", { desc = "Focus pane below" })
vim.keymap.set("n", "<Leader>k", "<C-w>k", { desc = "Focus pane above" })
vim.keymap.set("n", "<Leader>l", "<C-w>l", { desc = "Focus right pane" })
vim.keymap.set("n", "<Leader>q", "<cmd>close<cr>", { desc = "Close current split" })
vim.keymap.set("n", "<Leader>=", "<C-w>=", { desc = "Equalize split sizes" })

require("lazy").setup({
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      -- tokyonight for its treesitter/LSP group coverage, repainted with the
      -- Tomorrow Night Bright palette so nvim matches iTerm and Claude.
      require("tokyonight").setup({
        style = "night",
        on_colors = function(c)
          c.bg = "#000000"
          c.bg_dark = "#000000"
          c.bg_float = "#000000"
          c.bg_sidebar = "#000000"
          c.bg_statusline = "#000000"
          c.bg_highlight = "#2A2A2A"
          c.bg_visual = "#424242"
          c.fg = "#EAEAEA"
          c.fg_dark = "#EAEAEA"
          c.fg_sidebar = "#EAEAEA"
          c.comment = "#969896"
          c.red = "#D54E53"
          c.orange = "#E78C45"
          c.yellow = "#E7C547"
          c.green = "#B9CA4A"
          c.cyan = "#70C0B1"
          c.teal = "#70C0B1"
          c.blue = "#7AA6DA"
          c.purple = "#C397D8"
          c.magenta = "#C397D8"

          -- tokyonight's numbered accent slots drive some treesitter groups.
          c.blue0 = "#7AA6DA"
          c.blue1 = "#70C0B1"
          c.blue2 = "#7AA6DA"
          c.blue5 = "#70C0B1"
          c.blue6 = "#70C0B1"
          c.blue7 = "#7AA6DA"
          c.green1 = "#70C0B1"
          c.green2 = "#B9CA4A"
          c.magenta2 = "#C397D8"
          c.red1 = "#D54E53"
        end,
      })
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").install({
        "go", "gomod", "gosum", "gotmpl",
        "lua", "vim", "vimdoc", "query",
        "bash", "json", "yaml", "toml", "markdown", "markdown_inline",
        "hcl", "terraform", "dockerfile",
        "typescript", "tsx", "javascript", "css", "html",
        "python", "sql", "diff", "git_rebase", "gitcommit",
      })
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent files" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Symbols" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
    },
    opts = {
      defaults = {
        file_ignore_patterns = { "^%.git/", "node_modules/", "^vendor/" },
      },
      pickers = {
        find_files = { hidden = true },
      },
    },
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      pcall(telescope.load_extension, "fzf")
    end,
  },

  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    lazy = false,
    keys = {
      { "<leader>e", "<cmd>Neotree toggle<cr>", desc = "Toggle file tree" },
      { "<leader>E", "<cmd>Neotree focus<cr>", desc = "Focus file tree" },
    },
    opts = {
      -- Text glyphs instead of devicons: Monaco has no Nerd Font icon coverage.
      enable_git_status = true,
      enable_diagnostics = true,
      default_component_configs = {
        icon = {
          folder_closed = "▸",
          folder_open = "▾",
          folder_empty = "▹",
          default = " ",
        },
        git_status = {
          symbols = {
            added = "+",
            modified = "~",
            deleted = "-",
            renamed = "→",
            untracked = "?",
            ignored = "◌",
            unstaged = "✗",
            staged = "✓",
            conflict = "!",
          },
        },
        modified = { symbol = "●" },
      },
      window = {
        position = "left",
        width = 32,
      },
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = {
          hide_dotfiles = false,
          hide_gitignored = true,
        },
      },
    },
  },
})

-- On the main branch, highlighting is not a setup option — it is started per
-- buffer. Without this, parsers install but nothing gets colored.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
  callback = function(args)
    local ok = pcall(vim.treesitter.start, args.buf)
    if ok then
      vim.bo[args.buf].syntax = "off"
    end
  end,
})

-- LSP is built into nvim 0.11+, so gopls needs no plugin. Semantic tokens from
-- the server layer on top of treesitter for the richest highlighting.
vim.lsp.config("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
})
vim.lsp.enable("gopls")

-- A true restart: nothing in-process can re-evaluate lazy.nvim's plugin specs,
-- so in Neovide launch a detached replacement and quit. Reopens the same file in
-- the same cwd.
vim.api.nvim_create_user_command("Reload", function()
  if not vim.g.neovide then
    vim.cmd("source " .. vim.env.MYVIMRC)
    vim.notify("Sourced init.lua. Plugin spec changes still need a restart.")
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified and vim.api.nvim_buf_get_name(buf) == "" then
      vim.notify("Unnamed modified buffer — save or discard first", vim.log.levels.ERROR)
      return
    end
  end
  vim.cmd("wall")

  local exe = vim.fn.exepath("neovide")
  if exe == "" then
    exe = "/Applications/Neovide.app/Contents/MacOS/neovide"
  end

  local cmd = { exe, "--fork" }
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= "" then
    table.insert(cmd, file)
  end

  vim.system(cmd, { cwd = vim.fn.getcwd(), detach = true })
  vim.cmd("qall")
end, { desc = "Restart Neovide as if relaunched from the shell" })

-- GUI-only. Font size lives in neovide/config.toml, not here, so there is a
-- single source of truth for it.
if vim.g.neovide then
  vim.o.guifont = "Monaco:h12"

  vim.g.neovide_padding_top = 8
  vim.g.neovide_padding_bottom = 8
  vim.g.neovide_padding_left = 8
  vim.g.neovide_padding_right = 8

  vim.g.neovide_cursor_animation_length = 0
  vim.g.neovide_scroll_animation_length = 0
  vim.g.neovide_position_animation_length = 0
end
