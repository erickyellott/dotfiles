-- How long a normal scroll animates. Referenced twice below, so the autocmd
-- restores the same value the option sets.
local SCROLL_LENGTH = 0.3

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
        neovide_scroll_animation_length = SCROLL_LENGTH,
        -- Only covers jumps longer than one screen; see the autocmd below for
        -- the shorter ones.
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
    autocmds = {
      neovide_quiet_buffer_switch = {
        {
          event = "BufWinEnter",
          desc = "Snap rather than scroll when a buffer is first shown",
          callback = function()
            if not vim.g.neovide then return end
            -- Neovide animates any grid scroll, including the redraw when a new
            -- buffer appears. far_lines only suppresses jumps over a screen
            -- long, so a short file still slides. Zero the length across the
            -- redraw and restore it, leaving ordinary scrolling animated.
            vim.g.neovide_scroll_animation_length = 0
            vim.defer_fn(function()
              vim.g.neovide_scroll_animation_length = SCROLL_LENGTH
            end, 120)
          end,
        },
      },
    },
  },
}
