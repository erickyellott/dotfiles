---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      -- Open a directory as a sidebar rather than taking over the whole window.
      hijack_netrw_behavior = "open_default",
      filtered_items = { hide_dotfiles = false },
    },
    default_component_configs = {
      -- No per-filetype devicons; every file gets the plain default glyph.
      icon = { provider = false },
      -- One dot, colored by state, instead of nine different glyphs. staged and
      -- unstaged are blank: the distinction is not worth a column here.
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
