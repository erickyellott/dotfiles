---@type LazySpec
return {
  "folke/snacks.nvim",
  opts = {
    -- Outer `indent` is the snacks module; inner is the guide section. Options
    -- set on the outer table are silently ignored.
    indent = {
      indent = {
        -- Guides only in the cursor's scope; elsewhere the listchars tab glyph
        -- keeps tabs distinguishable from spaces.
        only_scope = true,
        only_current = true,
      },
    },
  },
}
