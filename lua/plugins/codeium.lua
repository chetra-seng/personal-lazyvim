return {
  "Exafunction/codeium.nvim",
  config = function()
    require("codeium").setup({
      enable_chat = true,
    })
  end,
  keys = {
    { "<leader>aa", "<cmd>Codeium Chat<cr>", desc = "Open Codeium chat in the browser" },
  }
}
