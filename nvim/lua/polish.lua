-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Blink the cursor in every mode (default only blinks in terminal mode).
-- 500/500 with no wait matches the macOS system text-cursor rate.
vim.opt.guicursor:append "a:blinkwait0-blinkon500-blinkoff500"
