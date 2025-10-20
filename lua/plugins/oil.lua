return {
  "stevearc/oil.nvim",
  ---@module 'oil'
  ---@type oil.SetupOpts
  opts = {},
  -- Optional dependencies
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  config = function()
    -- helper function to parse output
    local function parse_output(proc)
      local result = proc:wait()
      local ret = {}
      if result.code == 0 then
        for line in vim.gsplit(result.stdout, "\n", { plain = true, trimempty = true }) do
          -- Remove trailing slash
          line = line:gsub("/$", "")
          ret[line] = true
        end
      end
      return ret
    end

    -- build git status cache
    local function new_git_status()
      return setmetatable({}, {
        __index = function(self, key)
          local ignore_proc = vim.system(
            { "git", "ls-files", "--ignored", "--exclude-standard", "--others", "--directory" },
            {
              cwd = key,
              text = true,
            }
          )
          local tracked_proc = vim.system({ "git", "ls-tree", "HEAD", "--name-only" }, {
            cwd = key,
            text = true,
          })
          local ret = {
            ignored = parse_output(ignore_proc),
            tracked = parse_output(tracked_proc),
          }

          rawset(self, key, ret)
          return ret
        end,
      })
    end
    local git_status = new_git_status()

    -- Clear git status cache on refresh
    local refresh = require("oil.actions").refresh
    local orig_refresh = refresh.callback
    refresh.callback = function(...)
      git_status = new_git_status()
      orig_refresh(...)
    end
    require("oil").setup({
      hide_parent_dir = true,
      default_file_explorer = true,
      win_options = {
        signcolumn = "yes:2",
      },
      view_options = {
        show_hidden = false,
        is_hidden_file = function(name, bufnr)
          local dir = require("oil").get_current_dir(bufnr)
          local is_dotfile = vim.startswith(name, ".")
          -- if no local directory (e.g. for ssh connections), just hide dotfiles
          if not dir then
            return is_dotfile
          end
          -- dotfiles are considered hidden unless tracked
          if is_dotfile then
            return not git_status[dir].tracked[name]
          else
            -- Check if file is gitignored
            return git_status[dir].ignored[name]
          end
        end,
        -- This function defines what will never be shown, even when `show_hidden` is set
        is_always_hidden = function(name, bufnr)
          return name == ".."
        end,
      },
      float = {
        -- Padding around the floating window
        padding = 2,
        max_width = 0,
        max_height = 0,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
        -- optionally override the oil buffers window title with custom function: fun(winid: integer): string
        get_win_title = nil,
        -- preview_split: Split direction: "auto", "left", "right", "above", "below".
        preview_split = "auto",
        -- This is the config that will be passed to nvim_open_win.
        -- Change values here to customize the layout
        override = function(conf)
          return conf
        end,
      },
    })

    local function oil_paste_from_clipboard()
      local oil = require("oil")

      -- Detect OS and clipboard command
      local paste_cmd
      if vim.fn.has("mac") == 1 then
        paste_cmd = "pbpaste"
      elseif vim.fn.executable("wl-paste") == 1 then
        paste_cmd = "wl-paste"
      elseif vim.fn.executable("xclip") == 1 then
        paste_cmd = "xclip -selection clipboard -o"
      else
        vim.notify("No supported clipboard command found", vim.log.levels.ERROR)
        return
      end

      -- Get path(s) from clipboard
      local file_paths = vim.fn.systemlist(paste_cmd)
      if #file_paths == 0 then
        vim.notify("📋 Clipboard is empty or has no file paths", vim.log.levels.WARN)
        return
      end

      -- Get Oil's current directory
      local dest_dir = oil.get_current_dir()
      if not dest_dir then
        vim.notify("⚠️ Not inside Oil buffer", vim.log.levels.WARN)
        return
      end

      -- Copy each file
      for _, path in ipairs(file_paths) do
        local expanded = vim.fn.expand(path)
        if vim.fn.filereadable(expanded) == 1 or vim.fn.isdirectory(expanded) == 1 then
          local cmd = string.format("cp -r %q %q", expanded, dest_dir)
          local result = vim.fn.system(cmd)
          if vim.v.shell_error ~= 0 then
            vim.notify("❌ Copy failed: " .. result, vim.log.levels.ERROR)
          else
            vim.notify("✅ Copied " .. expanded .. " → " .. dest_dir, vim.log.levels.INFO)
          end
        else
          vim.notify("❌ No such file: " .. expanded, vim.log.levels.ERROR)
        end
      end

      -- Refresh Oil buffer
      refresh.callback()
    end

    -- Keymap inside Oil buffer
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "oil",
      callback = function()
        vim.keymap.set(
          "n",
          "<leader>P",
          oil_paste_from_clipboard,
          { buffer = true, desc = "Paste file from clipboard into Oil" }
        )
      end,
    })
  end,
  keymaps = {
    ["<leader>p"] = "image_wezterm", -- Define the keybinding for image preview
  },
  commands = {
    image_wezterm = function(state)
      local entry = state.entry
      if entry.type == "file" then
        -- Use the path to preview the image
        require("image_preview").PreviewImage(entry.path)
      end
    end,
  },
}
