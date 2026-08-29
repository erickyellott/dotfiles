-- Treesitter is configured through AstroCore; nvim-treesitter itself is only
-- the parser download utility. install.sh reads this list to build the parsers
-- ahead of time, so it is the single source of truth for them.

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
