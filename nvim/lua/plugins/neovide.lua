---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    options = {
      g = {
        -- Keep the cursor motion, drop the long smear.
        neovide_cursor_animation_length = 0.03,
        neovide_cursor_trail_size = 0.5,
        neovide_cursor_animate_in_insert_mode = false,
        neovide_cursor_animate_command_line = false,
        -- Keep normal scroll animation, but swapping buffers reads as one huge
        -- scroll -- 0 far lines makes those long jumps redraw instantly.
        neovide_scroll_animation_far_lines = 0,
        -- Both Option keys act as Meta so <M-Left>/<M-Right> reach nvim. This
        -- gives up composing special characters (é, ü) via Option.
        neovide_input_macos_option_key_is_meta = "both",
        -- Inset the text from the window edge so the first column and top line
        -- are not flush against the border.
        neovide_padding_top = 8,
        neovide_padding_bottom = 8,
        neovide_padding_left = 8,
        neovide_padding_right = 8,
      },
    },
  },
}
