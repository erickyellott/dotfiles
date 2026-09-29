---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      -- Open a directory as a sidebar rather than taking over the whole window.
      hijack_netrw_behavior = "open_default",
      filtered_items = { hide_dotfiles = false, hide_gitignored = false },
    },
    -- Insets the selector bar from the window edges. winbar is off; heirline.lua
    -- draws the selector in the tabline instead.
    source_selector = {
      winbar = false,
      padding = { left = 1, right = 1 },
      -- No dividers (they make the bar shift as the active tab moves).
      separator = { left = "", right = "" },
    },
    default_component_configs = {
      -- One column of indent gutter (AstroNvim default is 0, flush left).
      indent = { padding = 1 },
      -- No per-filetype devicons; every file gets the plain default glyph.
      icon = { provider = false },
      -- One dot, colored by state; staged/unstaged left blank.
      git_status = {
        symbols = {
          added = "●",
          modified = "●",
          deleted = "●",
          renamed = "●",
          untracked = "●",
          conflict = "●",
          ignored = "●",
          staged = "",
          unstaged = "",
        },
      },
    },
  },
}
