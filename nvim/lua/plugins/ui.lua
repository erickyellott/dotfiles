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
        -- base16 paints file and directory icons the same blue, so at a glance
        -- a file reads as a folder. Give files the plain foreground instead.
        hls.NeoTreeFileIcon =
          vim.tbl_extend("force", get_hlgroup "NeoTreeFileIcon", { fg = get_hlgroup("Normal").fg })

        -- Git state reads as green (new), yellow (changed), red (gone), in both
        -- the tree and the sign column. The stock groups paint changed/renamed
        -- blue and untracked orange, which does not map onto that. Colors come
        -- from the palette so they track the colorscheme rather than being
        -- pinned to Tomorrow Night Bright hexes.
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
