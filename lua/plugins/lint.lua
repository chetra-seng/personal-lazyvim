return {
  "nvim-lint",
  opts = {
    linters_by_ft = {
      beancount = { "bean_check" },
      javascript = { "eslint" },
      typescript = { "eslint" },
      typescriptreact = { "eslint" },
      javascriptreact = { "eslint" },
    },
  },
}
