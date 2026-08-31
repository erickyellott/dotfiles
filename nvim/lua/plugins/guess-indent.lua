---@type LazySpec
return {
  "NMAC427/guess-indent.nvim",
  opts = {
    -- Upstream only sets `expandtab = false` here, leaving `tabstop` at
    -- AstroNvim's global 2. Tab-indented files (Go, Makefiles) want 4.
    on_tab_options = {
      expandtab = false,
      tabstop = 4,
      shiftwidth = 4,
      softtabstop = 0,
    },
  },
}
