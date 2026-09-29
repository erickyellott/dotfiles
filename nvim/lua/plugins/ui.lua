local get_hlgroup = require("astroui").get_hlgroup

---@type LazySpec
return {
  "AstroNvim/astroui",
  ---@type AstroUIOpts
  opts = {
    colorscheme = "tomorrow-night-bright",
    -- Matches mini.icons' defaults (AstroNvim stock glyphs are smaller Seti
    -- outlines).
    icons = {
      FolderClosed = "󰉋",
      FolderOpen = "󰝰",
      FolderEmpty = "󰉌",
      DefaultFile = "󰈔",
    },
    status = {
      -- Drop the per-filetype devicon from the buffer tabs.
      components = {
        -- right=1 lands at 2 total (close_button pads itself by 1).
        tabline_file_info = { file_icon = false, padding = { left = 2, right = 1 } },
      },
      attributes = {
        buffer_active = { bold = true },
        buffer_visible = { bold = true },
      },
      -- Muted close buttons (stock uses the error color).
      colors = function(colors)
        colors.buffer_active_close_fg = colors.buffer_close_fg
        colors.buffer_visible_close_fg = colors.buffer_close_fg
        return colors
      end,
    },
    -- Neo-tree's Files/Bufs/Git source selector.
    highlights = {
      init = function()
        local hls = {}
        -- Active tab drops to the editor bg (reads as attached to the pane
        -- below); inactive sits on the tabline fill.
        hls.NeoTreeTabActive = vim.tbl_extend("force", get_hlgroup "NeoTreeTabActive", {
          fg = get_hlgroup("Normal").fg,
          bg = get_hlgroup("Normal").bg,
          bold = true,
        })
        hls.NeoTreeTabInactive = vim.tbl_extend("force", get_hlgroup "NeoTreeTabInactive", {
          fg = get_hlgroup("Comment").fg,
          bg = get_hlgroup("TabLineFill").bg,
          bold = true,
        })
        -- Dim split borders.
        local muted = get_hlgroup("Visual").bg
        for _, group in ipairs { "WinSeparator", "VertSplit" } do
          hls[group] = vim.tbl_extend("force", get_hlgroup(group), { fg = muted })
        end
        -- File icons in plain fg (dirs stay blue).
        hls.NeoTreeFileIcon =
          vim.tbl_extend("force", get_hlgroup "NeoTreeFileIcon", { fg = get_hlgroup("Normal").fg })

        -- Git state: green new, yellow changed, red gone.
        local ok, base16 = pcall(require, "base16-colorscheme")
        if ok and base16.colors then
          local new_, changed_, gone = base16.colors.base0B, base16.colors.base0A, base16.colors.base08
          local state = {
            NeoTreeGitAdded = new_,
            NeoTreeGitUntracked = new_,
            NeoTreeGitModified = changed_,
            NeoTreeGitRenamed = changed_,
            NeoTreeGitDeleted = gone,
            NeoTreeGitConflict = gone,
            GitSignsAdd = new_,
            GitSignsUntracked = new_,
            GitSignsChange = changed_,
            GitSignsChangedelete = changed_,
            GitSignsDelete = gone,
            GitSignsTopdelete = gone,
          }
          for group, fg in pairs(state) do
            hls[group] = vim.tbl_extend("force", get_hlgroup(group), { fg = fg })
          end
        end
        return hls
      end,
    },
  },
}
