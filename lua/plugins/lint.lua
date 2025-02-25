local function has_eslint_config()
  local current_dir = vim.fn.getcwd()
  local eslint_found = false

  -- Check current directory and parent directories for ESLint config
  while current_dir and current_dir ~= "" do
    local eslint_files = {
      ".eslintrc.js",
      ".eslintrc.json",
      "eslint.config.js",
      "eslint.config.ts",
      "package.json",
    }

    for _, eslint_file in ipairs(eslint_files) do
      local file_path = current_dir .. "/" .. eslint_file

      if vim.fn.filereadable(file_path) then
        eslint_found = true
        break
      end
    end

    if eslint_found then
      break
    end

    -- Move to the parent directory
    current_dir = vim.fn.fnamemodify(current_dir, ":h")
  end

  return eslint_found
end

return {
  "nvim-lint",
  opts = {
    linters_by_ft = {
      beancount = { "bean_check" },
      javascript = { has_eslint_config() and "eslint" or "biomejs" },
      typescript = { has_eslint_config() and "eslint" or "biomejs" },
      typescriptreact = { has_eslint_config() and "eslint" or "biomejs" },
      javascriptreact = { has_eslint_config() and "eslint" or "biomejs" },
    },
  },
  config = function()
    require("lint").try_lint(nil, {
      ignore_errors = true,
    })
  end,
}
