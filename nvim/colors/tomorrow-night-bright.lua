-- Tomorrow Night Bright, via base16-nvim (covers treesitter/LSP/plugin
-- highlight groups the original vimscript theme lacked). Matches Ghostty.
require("base16-colorscheme").setup {
  base00 = "#121212", -- background
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
