---@type LazySpec
return {
  "folke/snacks.nvim",
  opts = {
    -- The outer `indent` is the snacks module; the inner one is the guide
    -- section inside it. Options set on the outer table are silently ignored.
    indent = {
      indent = {
        -- Draw guides only inside the block the cursor is in. Everywhere else
        -- the listchars tab glyph shows through, so tabs stay distinguishable
        -- from spaces.
        only_scope = true,
        only_current = true,
      },
    },
  },
}
