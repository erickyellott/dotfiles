---@type LazySpec
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      -- Open a directory as a sidebar rather than taking over the whole window.
      hijack_netrw_behavior = "open_default",
      filtered_items = { hide_dotfiles = false, hide_gitignored = false },
    },
    -- AstroNvim centers the tabs already; this just insets the bar from the
    -- window edges so the outer tabs are not flush against them. winbar is off
    -- because heirline.lua draws the selector in the tabline instead.
    source_selector = {
      winbar = false,
      padding = { left = 1, right = 1 },
      -- No dividers. Only the inactive one carries a background, and the outer
      -- tabs have a separator on one side only, so the number of tinted columns
      -- changed as the active tab moved and the bar looked like it was shifting.
      -- Equal-width tabs plus a background on the active one says the same thing
      -- and holds still.
      separator = { left = "", right = "" },
    },
    default_component_configs = {
      -- AstroNvim sets this to 0, which puts the root folder icon hard against
      -- the left edge. One column of gutter reads a lot better.
      indent = { padding = 1 },
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
