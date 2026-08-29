local function move(dir)
  return function() require("smart-splits")["move_cursor_" .. dir]() end
end

---@type LazySpec
return {
  "AstroNvim/astrocore",
  -- Function opts, not a table: direct assignment replaces AstroNvim's
  -- <Leader>w entry, where a deep merge would keep its "<Cmd>w<CR>" rhs.
  ---@param opts AstroCoreOpts
  opts = function(_, opts)
    local maps = assert(opts.mappings)

    -- Replaces "Save"; <C-S> already force-writes in normal and visual mode.
    maps.n["<Leader>w"] = { desc = "󱂬 Windows" }

    -- Navigation. smart-splits rather than raw <C-w>h, to match the
    -- existing <C-h/j/k/l> maps AstroNvim sets in smart-splits.lua:13-16.
    maps.n["<Leader>wh"] = { move "left", desc = "Move to left split" }
    maps.n["<Leader>wj"] = { move "down", desc = "Move to lower split" }
    maps.n["<Leader>wk"] = { move "up", desc = "Move to upper split" }
    maps.n["<Leader>wl"] = { move "right", desc = "Move to right split" }

    -- Creation & management
    -- s/S match neo-tree, where s opens a vsplit and S a horizontal one.
    maps.n["<Leader>ws"] = { "<C-w>v", desc = "Split vertically" }
    maps.n["<Leader>wS"] = { "<C-w>s", desc = "Split horizontally" }
    maps.n["<Leader>wc"] = { "<C-w>c", desc = "Close split" }
    maps.n["<Leader>ww"] = { "<C-w>=", desc = "Equalize split sizes" }

    -- iTerm2/Ghostty muscle memory: Cmd+D splits right, Cmd+Shift+D splits
    -- down. Neovide only, since terminals swallow Cmd. Neovide reports shifted
    -- Cmd chords inconsistently across versions, hence both spellings.
    maps.n["<D-d>"] = { "<C-w>v", desc = "Split vertically" }
    for _, key in ipairs { "<D-S-d>", "<D-D>" } do
      maps.n[key] = { "<C-w>s", desc = "Split horizontally" }
    end

    -- Cmd+[ / Cmd+] cycle splits, Cmd+Shift+[ / ] cycle buffers -- the same
    -- division Ghostty and Chrome use. Note this inverts the old config, where
    -- Cmd+[ / Cmd+] cycled buffers.
    maps.n["<D-[>"] = { "<C-w>W", desc = "Previous split" }
    maps.n["<D-]>"] = { "<C-w>w", desc = "Next split" }
    for _, key in ipairs { "<D-S-[>", "<D-{>" } do
      maps.n[key] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" }
    end
    for _, key in ipairs { "<D-S-]>", "<D-}>" } do
      maps.n[key] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" }
    end

    maps.n["<D-t>"] = { "<Cmd>enew<CR>", desc = "New file" }

    -- Ghostty's Cmd+W: close the split, or the buffer when it is the last one.
    -- Only listed buffers count, so the neo-tree sidebar is not mistaken for a
    -- split worth closing.
    maps.n["<D-w>"] = {
      function()
        local wins = vim.tbl_filter(function(w)
          local buf = vim.api.nvim_win_get_buf(w)
          return vim.bo[buf].buflisted and vim.api.nvim_win_get_config(w).relative == ""
        end, vim.api.nvim_tabpage_list_wins(0))
        if #wins > 1 then
          vim.cmd.close()
        else
          require("astrocore.buffer").close()
        end
      end,
      desc = "Close split or buffer",
    }

    -- macOS Cmd chords. These must be mapped even if unused: an unmapped <D-x>
    -- falls through to the bare letter, so Cmd+C ran `c` (change) and ate the
    -- selection, Cmd+S ran `s`, Cmd+A ran `a`. All destructive.
    --
    -- Two traps, both of which make Cmd+C mangle the buffer instead of copying:
    -- in normal mode `"+y` is a bare operator left waiting for a motion, so the
    -- following keys are consumed as one and then run as normal-mode commands;
    -- and mode "v" covers Select as well as Visual, where the rhs is typed
    -- literally and replaces the selection. Hence "x" plus linewise normal-mode
    -- variants, and why the undo maps leave the mode before acting.
    maps.x["<D-c>"] = { '"+y', desc = "Copy to system clipboard" }
    maps.x["<D-x>"] = { '"+d', desc = "Cut to system clipboard" }
    maps.x["<D-v>"] = { '"+p', desc = "Paste from system clipboard" }
    maps.n["<D-c>"] = { '"+yy', desc = "Copy line to system clipboard" }
    maps.n["<D-x>"] = { '"+dd', desc = "Cut line to system clipboard" }
    maps.n["<D-v>"] = { '"+p', desc = "Paste from system clipboard" }
    maps.i["<D-v>"] = { "<C-r><C-o>+", desc = "Paste from system clipboard" }
    maps.c["<D-v>"] = { "<C-r><C-o>+", desc = "Paste from system clipboard" }
    maps.t["<D-v>"] = { [[<C-\><C-n>"+pi]], desc = "Paste from system clipboard" }
    maps.n["<D-a>"] = { "ggVG", desc = "Select all" }

    -- <Cmd> runs the ex command without leaving the current mode, so one
    -- mapping covers every mode rather than a mode dance per case.
    for _, mode in ipairs { "n", "i", "x", "s" } do
      maps[mode]["<D-s>"] = { "<Cmd>write<CR>", desc = "Write buffer" }
    end

    -- A bare `u` in Visual lowercases the selection instead of undoing, so the
    -- visual and select maps escape first.
    maps.n["<D-z>"] = { "u", desc = "Undo" }
    maps.x["<D-z>"] = { "<Esc>u", desc = "Undo" }
    maps.s["<D-z>"] = { "<Esc>u", desc = "Undo" }
    maps.i["<D-z>"] = { "<C-o>u", desc = "Undo" }
    for _, redo in ipairs { "<D-S-z>", "<D-Z>" } do
      maps.n[redo] = { "<C-r>", desc = "Redo" }
      maps.x[redo] = { "<Esc><C-r>", desc = "Redo" }
      maps.s[redo] = { "<Esc><C-r>", desc = "Redo" }
      maps.i[redo] = { "<C-o><C-r>", desc = "Redo" }
    end

    -- macOS text navigation: Cmd for line/document, Alt for words. Shift
    -- selects, unshifted only moves -- including out of an existing selection.
    -- In visual mode a plain motion already extends, so the Shift variants just
    -- need to *start* a selection from normal and insert. Insert uses <C-o>v
    -- rather than <Esc>v, which would shift the anchor a column left.
    local motions = {
      { "<D-Left>", "0", "<C-o>0", "start of line" },
      { "<D-Right>", "$", "<End>", "end of line" },
      { "<D-Up>", "gg", "<C-o>gg", "start of file" },
      { "<D-Down>", "G", "<C-o>G", "end of file" },
      { "<M-Left>", "b", "<C-o>b", "previous word" },
      { "<M-Right>", "e", "<C-o>e<Right>", "end of word" },
    }
    for _, m in ipairs(motions) do
      local key, motion, insert, what = m[1], m[2], m[3], m[4]
      maps.n[key] = { motion, desc = "Move to " .. what }
      -- Unshifted in visual collapses the selection and moves, as macOS does.
      -- A bare motion here would extend it instead.
      maps.x[key] = { "<Esc>" .. motion, desc = "Move to " .. what }
      maps.i[key] = { insert, desc = "Move to " .. what }

      local shifted = key:gsub("^<(%a)%-", "<%1-S-")
      maps.n[shifted] = { "v" .. motion, desc = "Select to " .. what }
      maps.x[shifted] = { motion, desc = "Select to " .. what }
      maps.i[shifted] = { "<C-o>v" .. motion, desc = "Select to " .. what }
    end
  end,
}
