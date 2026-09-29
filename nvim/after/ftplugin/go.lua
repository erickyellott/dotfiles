-- gofmt always uses hard tabs. Covers new buffers, which guess-indent
-- doesn't inspect until the first write.
vim.bo.expandtab = false
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 0
