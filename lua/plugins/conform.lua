return {
  "conform.nvim",
  opts = function()
    local biome = require("lint").linters.biomejs
    biome.args = {
      "--indent-style",
      "space",
    }

    local function get_correct_formatter()
      local biome_config = vim.fn.glob("biome.json")

      if biome_config ~= "" then
        return "biome"
      else
        return "prettier"
      end
    end

    return {
      formatters_by_ft = {
        ["javascript"] = { get_correct_formatter() },
        ["javascriptreact"] = { get_correct_formatter() },
        ["typescript"] = { get_correct_formatter() },
        ["typescriptreact"] = { get_correct_formatter() },
        ["vue"] = { get_correct_formatter() },
        ["css"] = { get_correct_formatter() },
        ["scss"] = { get_correct_formatter() },
        ["less"] = { get_correct_formatter() },
        ["html"] = { get_correct_formatter() },
        ["json"] = { get_correct_formatter() },
        ["rust"] = { "rustfmt" },
        ["beancount"] = { "bean-format" },
        ["java"] = { "google-java-format" },
        ["lua"] = { "stylua" },
      },
    }
  end,
}
