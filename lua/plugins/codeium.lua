return {
  "Exafunction/codeium.nvim",
  config = function()
    require("codeium").setup({
      -- Optionally disable cmp source if using virtual text only
      enable_cmp_source = false,
      virtual_text = {
        enabled = true,
      },
    })
  end,
}
