return {
  "nvim-neotest/neotest",
  dependencies = {
    { "marilari88/neotest-vitest" },
    { "thenbe/neotest-playwright" },
    { "fredrikaverpil/neotest-golang" },
  },
  opts = { adapters = { "neotest-vitest", "neotest-playwright", "neotest-golang" } },
  config = function()
    local neotest_golang_opts = {} -- Specify custom configuration
    require("neotest").setup({
      adapters = {
        require("neotest-vitest")({}),
        require("neotest-golang")(neotest_golang_opts), -- Registration
        require("neotest-playwright").adapter({
          options = {
            persist_project_selection = true,
            enable_dynamic_test_discovery = true,
          },
        }),
      },
    })
  end,
}
