-- AstroNvim reserves the sidebar-width slice of the tabline as blank padding,
-- and neo-tree draws its Files/Bufs/Git selector one row lower in the window's
-- winbar. That costs a whole row. Render the selector into the tabline slice
-- instead and turn the winbar off (see neo-tree.lua), so the tabs sit on the
-- same row as the buffer names.

---Build the selector string for the sidebar window, padded out to its width.
---@param winid integer
---@param width integer
---@return string
local function selector(winid, width)
  local blank = (" "):rep(width)

  local ok, sel = pcall(function()
    local state = require("neo-tree.sources.manager").get_state_for_window(winid)
    if not state then return nil end
    return require("neo-tree.ui.selector").get_selector(state, width)
  end)
  if not ok or type(sel) ~= "string" then return blank end

  -- Drop neo-tree's truncation marker. Harmless in a winbar it owns outright,
  -- but in the tabline it would make the selector the first thing sacrificed
  -- when the buffer list overflows.
  sel = (sel:gsub("%%<", ""))

  -- "equal" tab layout floors the per-tab width, so the string can come up a
  -- column or two short. Make up the difference or the buffer tabs shift left
  -- and stop lining up with the edge of the pane.
  local measured, rendered = pcall(vim.api.nvim_eval_statusline, sel, { use_tabline = true, maxwidth = 0 })
  if not measured then return blank end
  if rendered.width < width then
    sel = sel .. "%#NeoTreeTabInactive#" .. (" "):rep(width - rendered.width)
  end
  return sel
end

---@type LazySpec
return {
  "rebelot/heirline.nvim",
  opts = function(_, opts)
    if type(opts.tabline) ~= "table" or type(opts.tabline[1]) ~= "table" then return opts end
    opts.tabline[1] = {
      condition = function(self)
        self.winid = vim.api.nvim_tabpage_list_wins(0)[1]
        self.winwidth = vim.api.nvim_win_get_width(self.winid)
        return self.winwidth ~= vim.o.columns -- only apply to sidebars
          and not require("astrocore.buffer").is_valid(vim.api.nvim_win_get_buf(self.winid))
      end,
      { provider = function(self) return selector(self.winid, self.winwidth) end },
      -- The column the window separator lives in, which is not part of the
      -- sidebar's own width.
      { provider = " ", hl = { bg = "tabline_bg" } },
    }
    return opts
  end,
}
