-- Tomorrow Night Bright, rendered through base16-nvim so it covers treesitter,
-- LSP and plugin highlight groups that the original vimscript theme never had.
-- Palette taken verbatim from nvim-old/colors/Tomorrow-Night-Bright.vim, which
-- is the same theme Ghostty is set to.
require("base16-colorscheme").setup {
  base00 = "#121212", -- background (softened from #000000)
  base01 = "#2a2a2a", -- current line
  base02 = "#424242", -- selection
  base03 = "#969896", -- comment
  base04 = "#b4b7b4", -- dark foreground
  base05 = "#eaeaea", -- foreground
  base06 = "#e0e0e0", -- light foreground
  base07 = "#ffffff", -- light background
  base08 = "#d54e53", -- red
  base09 = "#e78c45", -- orange
  base0A = "#e7c547", -- yellow
  base0B = "#b9ca4a", -- green
  base0C = "#70c0b1", -- aqua
  base0D = "#7aa6da", -- blue
  base0E = "#c397d8", -- purple
  base0F = "#a3685a", -- brown
}

vim.g.colors_name = "tomorrow-night-bright"
