return {
  {
    "mfussenegger/nvim-jdtls",
    keys = {
      { "<leader>jsr", "<cmd>JavaSpringBootRun<cr>", desc = "Run Spring Boot", ft = "java" },
      { "<leader>jsd", "<cmd>JavaSpringBootDebug<cr>", desc = "Debug Spring Boot", ft = "java" },
      { "<leader>jst", "<cmd>JavaSpringBootToggle<cr>", desc = "Toggle Spring Boot terminal", ft = "java" },
      { "<leader>jsl", "<cmd>JavaSpringBootList<cr>", desc = "List Spring Boot terminals", ft = "java" },
      { "<leader>jss", "<cmd>JavaSpringBootStop<cr>", desc = "Stop Spring Boot terminal", ft = "java" },
    },
    opts = function(_, opts)
      local mason_path = vim.fn.stdpath("data") .. "/mason"
      local home = os.getenv("HOME")

      -- Build bundles for extensions
      local bundles = {}

      -- Include java-test bundle
      local java_test_path = mason_path .. "/packages/java-test"
      local java_test_bundle = vim.split(vim.fn.glob(java_test_path .. "/extension/server/*.jar"), "\n")
      if java_test_bundle[1] ~= "" then
        vim.list_extend(bundles, java_test_bundle)
      end

      -- Include java-debug-adapter bundle
      local java_debug_path = mason_path .. "/packages/java-debug-adapter"
      local java_debug_bundle =
        vim.split(vim.fn.glob(java_debug_path .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"), "\n")
      if java_debug_bundle[1] ~= "" then
        vim.list_extend(bundles, java_debug_bundle)
      end

      -- Include Spring Boot LS bundles (optional - uncomment if you have spring-boot-tools installed)
      -- local spring_boot_path = mason_path .. "/packages/spring-boot-tools"
      -- if vim.fn.isdirectory(spring_boot_path) == 1 then
      --   local spring_boot_bundle = vim.split(
      --     vim.fn.glob(spring_boot_path .. "/extension/language-server/*.jar"),
      --     "\n"
      --   )
      --   if spring_boot_bundle[1] ~= "" then
      --     vim.list_extend(bundles, spring_boot_bundle)
      --   end
      -- end

      -- Update init_options with bundles
      opts.init_options = opts.init_options or {}
      opts.init_options.bundles = bundles

      -- Extended client capabilities
      local extendedClientCapabilities = require("jdtls").extendedClientCapabilities
      extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
      opts.init_options.extendedClientCapabilities = extendedClientCapabilities

      -- Update settings
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          eclipse = {
            downloadSources = true,
          },
          maven = {
            downloadSources = true,
          },
          configuration = {
            updateBuildConfiguration = "interactive",
          },
          references = {
            includeDecompiledSources = true,
          },
          implementationsCodeLens = {
            enabled = true,
          },
          referenceCodeLens = {
            enabled = true,
          },
          inlayHints = {
            parameterNames = {
              enabled = "all",
            },
          },
          signatureHelp = {
            enabled = true,
            description = {
              enabled = true,
            },
          },
          sources = {
            organizeImports = {
              starThreshold = 9999,
              staticStarThreshold = 9999,
            },
          },
        },
      })

      -- Remove old lombok arg if present
      for i, arg in ipairs(opts.cmd or {}) do
        if arg:match("lombok.jar") then
          table.remove(opts.cmd, i)
        end
      end

      -- Add custom lombok path
      local lombok_jar = vim.fn.expand("$MASON/share/lombok-nightly/lombok.jar")
      table.insert(opts.cmd, string.format("--jvm-arg=-javaagent:%s", lombok_jar))

      -- Setup on_attach to configure DAP
      local original_on_attach = opts.on_attach
      opts.on_attach = function(client, bufnr)
        -- Call original on_attach if it exists
        if original_on_attach then
          original_on_attach(client, bufnr)
        end

        -- Setup DAP
        require("jdtls").setup_dap({ hotcodereplace = "auto" })
        require("jdtls.dap").setup_dap_main_class_configs()

        -- Add Spring Boot DAP configurations
        local dap = require("dap")
        if not dap.configurations.java then
          dap.configurations.java = {}
        end

        -- Function to find Spring Boot main class using JDTLS setup_dap_main_class_configs
        local function find_spring_boot_main_class(module)
          -- Get the DAP configurations that JDTLS already set up
          local dap_configs = dap.configurations.java or {}

          -- Debug: show all available configs
          if module then
            vim.notify("Looking for module: " .. module, vim.log.levels.INFO)
            for i, config in ipairs(dap_configs) do
              if config.mainClass and config.mainClass ~= "${file}" then
                vim.notify(
                  "Config "
                    .. i
                    .. ": projectName="
                    .. (config.projectName or "nil")
                    .. ", mainClass="
                    .. config.mainClass,
                  vim.log.levels.INFO
                )
              end
            end
          end

          -- Look through existing configs for a matching one
          for _, config in ipairs(dap_configs) do
            if config.mainClass and config.mainClass ~= "${file}" then
              if module then
                -- For multi-module, check if the config belongs to the selected module
                -- Try both exact match and pattern match
                if config.projectName then
                  if
                    config.projectName == module
                    or config.projectName:match(module)
                    or config.projectName:match("^" .. module .. "$")
                    or config.projectName:lower():match(module:lower())
                  then
                    vim.notify("Matched! Using: " .. config.mainClass, vim.log.levels.INFO)
                    return config.mainClass, config.projectName
                  end
                end
              else
                -- For single module, return the first valid main class
                return config.mainClass, config.projectName
              end
            end
          end

          vim.notify("No matching main class found for module: " .. (module or "default"), vim.log.levels.WARN)
          return nil, nil
        end

        -- Function to create Spring Boot launch config
        local function create_spring_boot_config(module, profile, build_tool)
          local args = ""

          if profile and profile ~= "" then
            args = "--spring.profiles.active=" .. profile
          end

          local mainClass, projectName = find_spring_boot_main_class(module)

          if not mainClass then
            -- Fallback: prompt user for main class
            vim.notify("Could not auto-detect main class. Please enter it manually.", vim.log.levels.WARN)
            vim.ui.input({
              prompt = "Enter main class (e.g., com.example.demo.DemoApplication): ",
            }, function(input_class)
              if not input_class or input_class == "" then
                vim.notify("No main class provided. Cancelling debug.", vim.log.levels.ERROR)
                return
              end

              local config = {
                type = "java",
                request = "launch",
                name = "Spring Boot"
                  .. (module and (" - " .. module) or "")
                  .. (profile and (" [" .. profile .. "]") or ""),
                mainClass = input_class,
                projectName = module or "",
                args = args,
                vmArgs = "-Dspring.output.ansi.enabled=ALWAYS",
                console = "integratedTerminal",
              }

              dap.run(config)
            end)
            return nil -- Signal that we'll handle it asynchronously
          end

          return {
            type = "java",
            request = "launch",
            name = "Spring Boot"
              .. (module and (" - " .. module) or "")
              .. (profile and (" [" .. profile .. "]") or ""),
            mainClass = mainClass,
            projectName = projectName or module or "",
            args = args,
            vmArgs = "-Dspring.output.ansi.enabled=ALWAYS",
            console = "integratedTerminal",
          }
        end

        -- Auto-refresh codelens on save
        vim.api.nvim_create_autocmd("BufWritePost", {
          buffer = bufnr,
          pattern = { "*.java" },
          callback = function()
            local _, _ = pcall(vim.lsp.codelens.refresh)
          end,
        })

        -- Detect if project is multi-module
        local function is_multi_module()
          local root_dir = vim.fn.getcwd()
          local pom_path = root_dir .. "/pom.xml"

          if vim.fn.filereadable(pom_path) == 1 then
            local content = vim.fn.readfile(pom_path)
            for _, line in ipairs(content) do
              if line:match("<modules>") then
                return true, "maven"
              end
            end
          end

          local settings_path = root_dir .. "/settings.gradle"
          if vim.fn.filereadable(settings_path) == 1 then
            local content = vim.fn.readfile(settings_path)
            for _, line in ipairs(content) do
              if line:match("include") then
                return true, "gradle"
              end
            end
          end

          return false, nil
        end

        -- Get list of modules
        local function get_modules()
          local root_dir = vim.fn.getcwd()
          local modules = {}

          -- Check for Maven modules
          local pom_path = root_dir .. "/pom.xml"
          if vim.fn.filereadable(pom_path) == 1 then
            local content = vim.fn.readfile(pom_path)
            local in_modules = false
            for _, line in ipairs(content) do
              if line:match("<modules>") then
                in_modules = true
              elseif line:match("</modules>") then
                in_modules = false
              elseif in_modules then
                local module = line:match("<module>(.-)</module>")
                if module then
                  table.insert(modules, module)
                end
              end
            end
          end

          -- Check for Gradle modules
          local settings_path = root_dir .. "/settings.gradle"
          if vim.fn.filereadable(settings_path) == 1 then
            local content = vim.fn.readfile(settings_path)
            for _, line in ipairs(content) do
              local module = line:match("include%s+['\"]:(.-)['\"]")
              if module then
                table.insert(modules, module)
              end
            end
          end

          return modules
        end

        local function get_spring_boot_runner(module, profile, debug, build_tool)
          local cmd = ""
          local root_dir = vim.fn.getcwd()

          if build_tool == "gradle" then
            local module_prefix = module and (":" .. module .. ":") or ":"
            if debug then
              -- For Gradle, add debug configuration
              -- Using port 5005 (standard Java debug port) to avoid conflict with app port
              local profile_args = profile and ("--args='--spring.profiles.active=" .. profile .. "'") or ""
              cmd = "./gradlew "
                .. module_prefix
                .. "bootRun "
                .. profile_args
                .. ' -Dorg.gradle.debug=false -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"'
            else
              cmd = "./gradlew "
                .. module_prefix
                .. "bootRun"
                .. (profile and (" --args='--spring.profiles.active=" .. profile .. "'") or "")
            end
          else
            -- Maven
            if module then
              -- For multi-module projects, cd into the module directory
              -- This ensures Maven can find the Spring Boot application in that specific module
              cmd = "cd " .. vim.fn.shellescape(root_dir .. "/" .. module) .. " && mvn spring-boot:run"
              if profile and profile ~= "" then
                cmd = cmd .. " -Dspring-boot.run.profiles=" .. profile
              end
              if debug then
                -- suspend=n means the app will start immediately without waiting for debugger
                -- fork=false is important for JVM args to work properly
                -- Using port 5005 (standard Java debug port) to avoid conflict with app port
                cmd = cmd
                  .. ' -Dspring-boot.run.fork=false -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"'
              end
            else
              -- Single module project - run from root
              cmd = "mvn spring-boot:run"
              if profile and profile ~= "" then
                cmd = cmd .. " -Dspring-boot.run.profiles=" .. profile
              end
              if debug then
                cmd = cmd
                  .. ' -Dspring-boot.run.fork=false -Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"'
              end
            end
          end

          return cmd
        end

        -- Track running Spring Boot terminals
        local running_terminals = {}

        local function run_spring_boot(debug)
          local is_multi, build_tool = is_multi_module()

          local function start_and_debug(module, profile)
            if debug then
              -- Use DAP to launch Spring Boot directly
              vim.notify("Starting Spring Boot in debug mode via DAP...", vim.log.levels.INFO)

              local config = create_spring_boot_config(module, profile, build_tool)

              -- config will be nil if it's being handled asynchronously (manual input)
              if config == nil then
                return
              end

              -- Store the config and start debugging
              dap.run(config)
            else
              -- Non-debug mode: use terminal
              local cmd = get_spring_boot_runner(module, profile, false, build_tool)
              local terminal_name = module and ("SpringBoot[" .. module .. "]") or "SpringBoot"

              vim.notify("Running: " .. cmd, vim.log.levels.INFO)

              -- Create a new terminal with a specific name
              vim.cmd("15sp|term " .. cmd)

              -- Set terminal buffer name for easy identification
              local term_bufnr = vim.api.nvim_get_current_buf()
              vim.api.nvim_buf_set_name(term_bufnr, terminal_name)

              -- Track this terminal
              running_terminals[module or "default"] = {
                bufnr = term_bufnr,
                name = terminal_name,
                profile = profile,
              }

              -- Return to previous window
              vim.cmd("wincmd p")
            end
          end

          if is_multi then
            local modules = get_modules()

            if #modules == 0 then
              vim.notify("No modules found in multi-module project", vim.log.levels.WARN)
              return
            end

            -- Show module selection
            vim.ui.select(modules, {
              prompt = "Select module to run:",
              format_item = function(item)
                return item
              end,
            }, function(choice)
              if choice then
                -- Ask for profile (optional)
                vim.ui.input({
                  prompt = "Spring profile (optional, press Enter to skip): ",
                }, function(profile)
                  start_and_debug(choice, profile ~= "" and profile or nil)
                end)
              end
            end)
          else
            -- Single module project
            vim.ui.input({
              prompt = "Spring profile (optional, press Enter to skip): ",
            }, function(profile)
              start_and_debug(nil, profile ~= "" and profile or nil)
            end)
          end
        end

        -- Function to toggle a Spring Boot terminal
        local function toggle_spring_boot_terminal()
          local active_terminals = {}

          for module, terminal_info in pairs(running_terminals) do
            -- Check if buffer still exists
            if vim.api.nvim_buf_is_valid(terminal_info.bufnr) then
              table.insert(active_terminals, {
                module = module,
                name = terminal_info.name,
                bufnr = terminal_info.bufnr,
                profile = terminal_info.profile,
                winid = terminal_info.winid,
              })
            else
              -- Clean up invalid terminals
              running_terminals[module] = nil
            end
          end

          if #active_terminals == 0 then
            vim.notify("No Spring Boot terminals running", vim.log.levels.INFO)
            return
          end

          -- Show list of running terminals
          local items = {}
          for _, term in ipairs(active_terminals) do
            local display = term.name
            if term.profile then
              display = display .. " [" .. term.profile .. "]"
            end

            -- Check if terminal is currently visible
            local is_visible = false
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if vim.api.nvim_win_get_buf(win) == term.bufnr then
                is_visible = true
                break
              end
            end

            if is_visible then
              display = "✓ " .. display
            else
              display = "  " .. display
            end

            table.insert(items, display)
          end

          vim.ui.select(items, {
            prompt = "Toggle Spring Boot terminal (✓ = visible):",
            format_item = function(item)
              return item
            end,
          }, function(choice, idx)
            if choice and idx then
              local selected = active_terminals[idx]

              -- Check if terminal is currently visible
              local visible_win = nil
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_get_buf(win) == selected.bufnr then
                  visible_win = win
                  break
                end
              end

              if visible_win then
                -- Terminal is visible, close it
                vim.api.nvim_win_close(visible_win, false)
              else
                -- Terminal is hidden, open it
                vim.cmd("15sp|buffer " .. selected.bufnr)
                local new_win = vim.api.nvim_get_current_win()
                running_terminals[selected.module].winid = new_win
              end
            end
          end)
        end

        -- Function to list running Spring Boot terminals
        local function list_spring_boot_terminals()
          local active_terminals = {}

          for module, terminal_info in pairs(running_terminals) do
            -- Check if buffer still exists
            if vim.api.nvim_buf_is_valid(terminal_info.bufnr) then
              table.insert(active_terminals, {
                module = module,
                name = terminal_info.name,
                bufnr = terminal_info.bufnr,
                profile = terminal_info.profile,
              })
            else
              -- Clean up invalid terminals
              running_terminals[module] = nil
            end
          end

          if #active_terminals == 0 then
            vim.notify("No Spring Boot terminals running", vim.log.levels.INFO)
            return
          end

          -- Show list of running terminals
          local items = {}
          for _, term in ipairs(active_terminals) do
            local display = term.name
            if term.profile then
              display = display .. " [" .. term.profile .. "]"
            end
            table.insert(items, display)
          end

          vim.ui.select(items, {
            prompt = "Running Spring Boot terminals:",
            format_item = function(item)
              return item
            end,
          }, function(choice, idx)
            if choice and idx then
              local selected = active_terminals[idx]
              -- Focus on the selected terminal
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_get_buf(win) == selected.bufnr then
                  vim.api.nvim_set_current_win(win)
                  return
                end
              end
              -- If terminal window is not visible, open it
              vim.cmd("15sp|buffer " .. selected.bufnr)
            end
          end)
        end

        -- Function to stop a running Spring Boot terminal
        local function stop_spring_boot_terminal()
          local active_terminals = {}

          for module, terminal_info in pairs(running_terminals) do
            if vim.api.nvim_buf_is_valid(terminal_info.bufnr) then
              table.insert(active_terminals, {
                module = module,
                name = terminal_info.name,
                bufnr = terminal_info.bufnr,
                profile = terminal_info.profile,
              })
            else
              running_terminals[module] = nil
            end
          end

          if #active_terminals == 0 then
            vim.notify("No Spring Boot terminals running", vim.log.levels.INFO)
            return
          end

          -- Show list to stop
          local items = {}
          for _, term in ipairs(active_terminals) do
            local display = term.name
            if term.profile then
              display = display .. " [" .. term.profile .. "]"
            end
            table.insert(items, display)
          end

          vim.ui.select(items, {
            prompt = "Select terminal to stop:",
            format_item = function(item)
              return item
            end,
          }, function(choice, idx)
            if choice and idx then
              local selected = active_terminals[idx]
              -- Delete the terminal buffer
              vim.api.nvim_buf_delete(selected.bufnr, { force = true })
              running_terminals[selected.module] = nil
              vim.notify("Stopped: " .. selected.name, vim.log.levels.INFO)
            end
          end)
        end

        vim.api.nvim_create_user_command("JavaSpringBootRun", function()
          run_spring_boot()
        end, { desc = "Run Spring Boot application" })

        vim.api.nvim_create_user_command("JavaSpringBootDebug", function()
          run_spring_boot(true)
        end, { desc = "Debug Spring Boot application" })

        vim.api.nvim_create_user_command("JavaSpringBootToggle", function()
          toggle_spring_boot_terminal()
        end, { desc = "Toggle Spring Boot terminal visibility" })

        vim.api.nvim_create_user_command("JavaSpringBootList", function()
          list_spring_boot_terminals()
        end, { desc = "List running Spring Boot terminals" })

        vim.api.nvim_create_user_command("JavaSpringBootStop", function()
          stop_spring_boot_terminal()
        end, { desc = "Stop a Spring Boot terminal" })
      end

      return opts
    end,
  },
}
