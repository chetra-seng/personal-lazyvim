local function has_prettier_config()
  local current_dir = vim.fn.getcwd()
  local prettier_config = false

  -- Check current directory and parent directories for Prettier config
  while current_dir and current_dir ~= "" do
    local eslint_files = {
      ".prettierrc",
      ".prettierrc.json",
      ".prettierrc.yml",
      ".prettierrc.yaml",
      ".prettierrc.json5",
      ".prettierrc.mjs",
      ".prettierrc.cjs",
      "prettier.config.mjs",
      "prettier.config.cjs",
    }

    for _, prettier_file in ipairs(eslint_files) do
      local file_path = current_dir .. "/" .. prettier_file

      if vim.fn.filereadable(file_path) then
        prettier_config = true
        break
      end
    end

    if prettier_config then
      break
    end

    -- Move to the parent directory
    current_dir = vim.fn.fnamemodify(current_dir, ":h")
  end

  return prettier_config
end

return {
  "conform.nvim",
  opts = function()
    local biome = require("lint").linters.biomejs
    biome.args = {
      "--indent-style",
      "space",
    }

    return {
      formatters_by_ft = {
        ["javascript"] = { has_prettier_config() and "prettier" or "biomejs" },
        ["javascriptreact"] = { has_prettier_config() and "prettier" or "biomejs" },
        ["typescript"] = { has_prettier_config() and "prettier" or "biomejs" },
        ["typescriptreact"] = { has_prettier_config() and "prettier" or "biomejs" },
        ["vue"] = { has_prettier_config() and "prettier" or "biomejs" },
        ["css"] = { has_prettier_config() and "prettier" or "biomejs" },
        ["scss"] = { has_prettier_config() and "prettier" or "biomejs" },
        ["less"] = { has_prettier_config() and "prettier" or "biomejs" },
        ["html"] = { has_prettier_config() and "prettier" or "biomejs" },
        ["json"] = { has_prettier_config() and "prettier" or "biomejs" },
        ["rust"] = { "rustfmt" },
        ["beancount"] = { "bean-format" },
        ["java"] = { "google-java-format" },
        ["lua"] = { "stylua" },
        ["go"] = { "gofmt" },
      },
    }
  end,
}
