return {
  {
    "mfussenegger/nvim-jdtls",
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
                vim.notify("Config " .. i .. ": projectName=" .. (config.projectName or "nil") .. ", mainClass=" .. config.mainClass, vim.log.levels.INFO)
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
                  if config.projectName == module or
                     config.projectName:match(module) or
                     config.projectName:match("^" .. module .. "$") or
                     config.projectName:lower():match(module:lower()) then
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
                name = "Spring Boot" .. (module and (" - " .. module) or "") .. (profile and (" [" .. profile .. "]") or ""),
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
            name = "Spring Boot" .. (module and (" - " .. module) or "") .. (profile and (" [" .. profile .. "]") or ""),
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

        -- Custom keymaps for Java testing and Spring Boot

        -- Get current module from file path
        local function get_current_module()
          local file_path = vim.fn.expand("%:p")
          local root_dir = vim.fn.getcwd()
          local relative_path = file_path:sub(#root_dir + 2) -- +2 for the slash

          -- Extract module name (first directory in path)
          local module = relative_path:match("^([^/]+)/")

          -- Check if this module exists in pom.xml or settings.gradle
          local modules = get_modules()
          for _, m in ipairs(modules) do
            if m == module then
              return module
            end
          end

          return nil
        end

        local function get_test_runner(test_name, debug, build_tool)
          local module = get_current_module()
          local module_param = module and ("-pl " .. module .. " ") or ""

          if build_tool == "gradle" then
            local module_prefix = module and (":" .. module .. ":") or ":"
            if debug then
              return "./gradlew " .. module_prefix .. "test --tests " .. test_name .. " --debug-jvm"
            else
              return "./gradlew " .. module_prefix .. "test --tests " .. test_name
            end
          else
            -- Maven
            if debug then
              return 'mvn ' .. module_param .. 'test -Dmaven.surefire.debug -Dtest="' .. test_name .. '"'
            end
            return 'mvn ' .. module_param .. 'test -Dtest="' .. test_name .. '"'
          end
        end

        local function run_java_test_method(debug)
          local _, build_tool = is_multi_module()
          build_tool = build_tool or "maven"

          -- Try to get method name using LSP or treesitter
          local method_name = vim.fn.expand("<cword>")
          local class_name = vim.fn.expand("%:t:r")
          local full_test_name = class_name .. "#" .. method_name

          vim.cmd("term " .. get_test_runner(full_test_name, debug, build_tool))
        end

        local function run_java_test_class(debug)
          local _, build_tool = is_multi_module()
          build_tool = build_tool or "maven"

          local class_name = vim.fn.expand("%:t:r")
          vim.cmd("term " .. get_test_runner(class_name, debug, build_tool))
        end

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
                .. " -Dorg.gradle.debug=false -Dspring-boot.run.jvmArguments=\"-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005\""
            else
              cmd = "./gradlew "
                .. module_prefix
                .. "bootRun"
                .. (profile and (" --args='--spring.profiles.active=" .. profile .. "'") or "")
            end
          else
            -- Maven
            local module_param = module and ("-pl " .. module .. " -am ") or ""

            if debug then
              -- suspend=n means the app will start immediately without waiting for debugger
              -- fork=false is important for JVM args to work properly
              -- Using port 5005 (standard Java debug port) to avoid conflict with app port
              cmd = "mvn "
                .. module_param
                .. "spring-boot:run -Dspring-boot.run.fork=false "
                .. (profile and ("-Dspring-boot.run.profiles=" .. profile .. " ") or "")
                .. '-Dspring-boot.run.jvmArguments="-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=5005"'
            else
              cmd = "mvn "
                .. module_param
                .. "spring-boot:run"
                .. (profile and (" -Dspring-boot.run.profiles=" .. profile) or "")
            end
          end

          return cmd
        end

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
              vim.notify("Running: " .. cmd, vim.log.levels.INFO)
              vim.cmd("15sp|term " .. cmd)
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

        -- Keymaps for Java testing and Spring Boot
        vim.keymap.set("n", "<leader>Tm", function()
          run_java_test_method()
        end, { buffer = bufnr, desc = "Run Java test method" })

        vim.keymap.set("n", "<leader>TM", function()
          run_java_test_method(true)
        end, { buffer = bufnr, desc = "Debug Java test method" })

        vim.keymap.set("n", "<leader>Tc", function()
          run_java_test_class()
        end, { buffer = bufnr, desc = "Run Java test class" })

        vim.keymap.set("n", "<leader>TC", function()
          run_java_test_class(true)
        end, { buffer = bufnr, desc = "Debug Java test class" })

        vim.keymap.set("n", "<F9>", function()
          run_spring_boot()
        end, { buffer = bufnr, desc = "Run Spring Boot" })

        vim.keymap.set("n", "<F10>", function()
          run_spring_boot(true)
        end, { buffer = bufnr, desc = "Debug Spring Boot" })
      end

      return opts
    end,
  },
}
