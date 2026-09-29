---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    options = {
      opt = {
        -- Always show whitespace; glyphs are Latin-1 so Monaco renders them
        -- without falling back to another font.
        list = true,
        tabstop = 4,
        listchars = { tab = "· ", eol = "¬", trail = "·", nbsp = "¤" },
        colorcolumn = "80",
      },
    },
  },
}
