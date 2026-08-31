---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    options = {
      opt = {
        -- Always show whitespace. These glyphs are all Latin-1, which Monaco
        -- covers in full, so they render without falling back to another font.
        list = true,
        tabstop = 4,
        listchars = { tab = "· ", eol = "¬", trail = "·", nbsp = "¤" },
        colorcolumn = "80",
      },
    },
  },
}
