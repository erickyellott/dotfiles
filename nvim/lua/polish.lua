-- This will run last in the setup process.
-- This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- A true restart: nothing in-process can re-evaluate lazy.nvim's plugin specs,
-- so in Neovide launch a detached replacement and quit. Reopens the same file in
-- the same cwd.
vim.api.nvim_create_user_command("Reload", function()
  if not vim.g.neovide then
    vim.cmd("source " .. vim.env.MYVIMRC)
    vim.notify "Sourced init.lua. Plugin spec changes still need a restart."
    return
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified and vim.api.nvim_buf_get_name(buf) == "" then
      vim.notify("Unnamed modified buffer — save or discard first", vim.log.levels.ERROR)
      return
    end
  end
  vim.cmd "wall"

  local exe = vim.fn.exepath "neovide"
  if exe == "" then exe = "/Applications/Neovide.app/Contents/MacOS/neovide" end

  local cmd = { exe, "--fork" }
  local file = vim.api.nvim_buf_get_name(0)
  if file ~= "" then table.insert(cmd, file) end

  vim.system(cmd, { cwd = vim.fn.getcwd(), detach = true })
  vim.cmd "qall"
end, { desc = "Restart Neovide as if relaunched from the shell" })

-- Blink the cursor in every mode. Only `t:` (terminal) blinks by default; the
-- `a:` entry layers blink onto all modes without restating their shapes.
-- 500/500 with no wait is the macOS system text-cursor rate, so this matches
-- Ghostty rather than pausing before it starts.
vim.opt.guicursor:append "a:blinkwait0-blinkon500-blinkoff500"
