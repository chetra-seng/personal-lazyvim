return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = true,
  keys = {
    {
      "<leader>tt",
      function()
        local count = vim.v.count1
        require("toggleterm").toggle(count)
      end,
      desc = "Toggle first or specific terminal",
    },
    {
      "<leader>tT",
      function()
        require("toggleterm").toggle()
      end,
      desc = "Toggle all terminals",
    },
    {
      "<leader>tv",
      function()
        local count = vim.v.count1
        require("toggleterm").toggle(count, 0, vim.fn.getcwd(), "vertical")
      end,
      desc = "Toggle vertical terminal",
    },
    {
      "<leader>th",
      function()
        local count = vim.v.count1
        require("toggleterm").toggle(count, 10, vim.fn.getcwd(), "horizontal")
      end,
      desc = "Toggle horizontal terminal",
    },
  },
}
