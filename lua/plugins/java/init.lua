return {
  "nvim-java/nvim-java",
  config = false,
  dependencies = {
    {
      "neovim/nvim-lspconfig",
      opts = {
        servers = {
          jdtls = {
            -- Your custom jdtls settings goes here
            handlers = {
              -- By assigning an empty function, you can remove the notifications
              -- printed to the cmd
              ["$/progress"] = function(_, result, ctx) end,
            },
          },
        },
        setup = {
          jdtls = function()
            require("java").setup({
              -- Your custom nvim-java configuration goes here
            })
          end,
        },
      },
    },
  },
  keys = {
    {
      "<leader>jb",
      "<cmd>JavaBuildBuildWorkspace<cr>",
      desc = "Build java workspace",
    },
    {
      "<leader>jj",
      "<cmd>JavaRunnerRunMain<cr>",
      desc = "Java run main class of application",
    },
    {
      "<leader>js",
      "<cmd>JavaRunnerStopMain<cr>",
      desc = "Java stop main class of application",
    },
    {
      "<leader>jp",
      "<cmd>JavaProfile<cr>",
      desc = "Java open profile UI",
    },
    {
      "<leader>jc",
      "<cmd>JavaTestRunCurrentClass<cr>",
      desc = "Java run test for current class",
    },
    {
      "<leader>jC",
      "<cmd>JavaTestDebugCurrentClass<cr>",
      desc = "Java run debug test for current class",
    },
    {
      "<leader>jm",
      "<cmd>JavaTestRunCurrentMethod<cr>",
      desc = "Java run test for current method",
    },
    {
      "<leader>jM",
      "<cmd>JavaTestDebugCurrentMethod<cr>",
      desc = "Java run debug test for current method",
    },
    {
      "<leader>jt",
      "<cmd>JavaRunnerToggleLogs<cr>",
      desc = "Java toggle runner log",
    },
    {
      "<leader>jr",
      "<cmd>JavaTestViewLastReport<cr>",
      desc = "Java view last test report",
    },

    {
      "<leader>jR",
      "<cmd>JavaSettingsChangeRuntime<cr>",
      desc = "Java change jdk runtime",
    },
  },
}
