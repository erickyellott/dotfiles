-- Configured via AstroCore; nvim-treesitter is just the parser downloader.
-- install.sh reads this list, so it's the source of truth for parsers.

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true,
      indent = true,
      auto_install = true,
      ensure_installed = {
        "go", "gomod", "gosum", "gotmpl",
        "lua", "vim", "vimdoc", "query",
        "bash", "json", "yaml", "toml", "markdown", "markdown_inline",
        "hcl", "terraform", "dockerfile",
        "typescript", "tsx", "javascript", "css", "html",
        "python", "sql", "diff", "git_rebase", "gitcommit",
      },
    },
  },
}
