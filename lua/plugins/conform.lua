local function has_prettier_config()
  local current_dir = vim.fn.expand("%:p:h") -- start from current file
  local max_depth = 20
  local depth = 0

  while current_dir and current_dir ~= "" and current_dir ~= "/" and depth < max_depth do
    local prettier_files = {
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

    for _, file in ipairs(prettier_files) do
      local path = current_dir .. "/" .. file
      if vim.fn.filereadable(path) == 1 then
        -- Found a prettier config
        -- print("Found prettier config at:", path) -- optional debug
        return true
      end
    end

    -- Go up one directory
    local parent = vim.fn.fnamemodify(current_dir, ":h")
    if parent == current_dir then
      break
    end
    current_dir = parent
    depth = depth + 1
  end

  return false
end

return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    if not opts.formatters then
      opts.formatters = {}
    end

    opts.formatters.biome = {
      args = {
        "check",
        "--write",
        "--jsx-quote-style",
        "double",
        "--javascript-formatter-quote-style",
        "double",
        "--indent-style",
        "space",
        "--indent-width",
        "2",
        "--line-ending",
        "lf",
        "--semicolons",
        "always",
        "--stdin-file-path",
        "$FILENAME",
      },
    }

    opts.formatters.sqlfluff = {
      args = { "format", "--dialect", "postgres", "-" },
    }

    if not opts.formatters_by_ft then
      opts.formatters_by_ft = {}
    end

    local use_prettier = has_prettier_config()

    opts.formatters_by_ft.javascript = { use_prettier and "prettier" or "biome" }
    opts.formatters_by_ft.javascriptreact = { use_prettier and "prettier" or "biome" }
    opts.formatters_by_ft.typescript = { use_prettier and "prettier" or "biome" }
    opts.formatters_by_ft.typescriptreact = { use_prettier and "prettier" or "biome" }
    opts.formatters_by_ft.vue = { use_prettier and "prettier" or "biome" }
    opts.formatters_by_ft.css = { use_prettier and "prettier" or "biome" }
    opts.formatters_by_ft.scss = { use_prettier and "prettier" or "biome" }
    opts.formatters_by_ft.less = { use_prettier and "prettier" or "biome" }
    opts.formatters_by_ft.html = { use_prettier and "prettier" or "biome" }
    opts.formatters_by_ft.json = { use_prettier and "prettier" or "biome" }
    opts.formatters_by_ft.htmlangular = { "prettier" }
    opts.formatters_by_ft.rust = { "rustfmt" }
    opts.formatters_by_ft.beancount = { "bean-format" }
    opts.formatters_by_ft.java = { "google-java-format" }
    opts.formatters_by_ft.lua = { "stylua" }
    opts.formatters_by_ft.go = { "gofmt" }
    opts.formatters_by_ft.xml = { "xmlformatter" }
    opts.formatters_by_ft.sql = { "sqlfluff" }

    return opts
  end,
  keys = {
    {
      "<leader>cf",
      function()
        local bufname = vim.api.nvim_buf_get_name(0)
        local filetype = vim.bo.filetype

        -- Check if it's a dadbod-ui buffer or a buffer in .local/share (dadbod storage)
        if bufname:match("%.local/share") or bufname:match("^dbui://") or vim.bo.buftype ~= "" then
          -- Use custom SQL formatting for special buffers
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local content = table.concat(lines, "\n")
          local tmp_file = vim.fn.tempname() .. ".sql"

          local file = io.open(tmp_file, "w")
          if file then
            file:write(content)
            file:close()

            vim.fn.system("sqlfluff format --dialect postgres " .. tmp_file)

            file = io.open(tmp_file, "r")
            if file then
              local formatted = file:read("*all")
              file:close()

              local formatted_lines = vim.split(formatted, "\n", { plain = true })
              if formatted_lines[#formatted_lines] == "" then
                table.remove(formatted_lines)
              end
              vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted_lines)
              vim.notify("SQL formatted successfully", vim.log.levels.INFO)
            end

            os.remove(tmp_file)
          end
        else
          -- Use conform.nvim for normal files
          require("conform").format({ bufnr = vim.api.nvim_get_current_buf() })
        end
      end,
      desc = "Format code",
      mode = { "n", "v" },
    },
  },
}
