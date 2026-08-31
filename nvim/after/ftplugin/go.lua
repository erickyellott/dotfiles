-- gofmt indents with hard tabs, always. Set the display width, not the
-- character. Covers new buffers, which guess-indent doesn't inspect until the
-- first write.
vim.bo.expandtab = false
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 0
