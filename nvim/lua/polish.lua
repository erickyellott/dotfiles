-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Blink the cursor in every mode. Only `t:` (terminal) blinks by default; the
-- `a:` entry layers blink onto all modes without restating their shapes.
-- 500/500 with no wait is the macOS system text-cursor rate, so this matches
-- Ghostty rather than pausing before it starts.
vim.opt.guicursor:append "a:blinkwait0-blinkon500-blinkoff500"
