local get_hlgroup = require("astroui").get_hlgroup

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    colorscheme = "tomorrow-night-bright",
    -- Filled folders and a blank page, matching mini.icons' own defaults.
    -- AstroNvim's stock glyphs are the smaller Seti outline variants.
    icons = {
      FolderClosed = "󰉋",
      FolderOpen = "󰝰",
      FolderEmpty = "󰉌",
      DefaultFile = "󰈔",
    },
    status = {
      -- Drop the per-filetype devicon from the buffer tabs.
      components = {
        tabline_file_info = { file_icon = false },
      },
      attributes = {
        buffer_active = { bold = true },
        buffer_visible = { bold = true },
      },
    },
    -- Neo-tree's Files/Bufs/Git source selector.
    highlights = {
      init = function()
        local hls = {}
        for _, group in ipairs { "NeoTreeTabActive", "NeoTreeTabInactive" } do
          hls[group] = vim.tbl_extend("force", get_hlgroup(group), { bold = true })
        end
        -- base16 paints split borders in the foreground color, which reads as a
        -- bright white bar. Use the selection color so it recedes; taking it
        -- from Visual keeps it correct if the colorscheme changes.
        local muted = get_hlgroup("Visual").bg
        for _, group in ipairs { "WinSeparator", "VertSplit" } do
          hls[group] = vim.tbl_extend("force", get_hlgroup(group), { fg = muted })
        end
        return hls
      end,
    },
  },
}
