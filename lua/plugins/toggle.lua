return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = true,
  keys = {
    {
      "<leader>tt",
      function()
        local count = vim.v.count1
        if count == 1 then
          require("toggleterm").toggle()
        else
          require("toggleterm").toggle(count)
        end
      end,
      desc = "Toggle specific or all terminals",
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
