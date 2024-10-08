return {
  "conform.nvim",
  opts = {
    formatters_by_ft = {
      ["javascript"] = { "prettier" },
      ["javascriptreact"] = { "prettier" },
      ["typescript"] = { "prettier" },
      ["typescriptreact"] = { "prettier" },
      ["vue"] = { "prettier" },
      ["css"] = { "prettier" },
      ["scss"] = { "prettier" },
      ["less"] = { "prettier" },
      ["html"] = { "prettier" },
      ["json"] = { "prettier" },
      ["rust"] = { "rustfmt" },
      ["beancount"] = { "bean-format" },
      ["java"] = { "google-java-format" },
    },
  },
}
