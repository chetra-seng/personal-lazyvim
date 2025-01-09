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
  opts = function()
    LazyVim.cmp.actions.ai_accept = function()
      if require("codeium.virtual_text").get_current_completion_item() then
        LazyVim.create_undo()
        vim.api.nvim_input(require("codeium.virtual_text").accept())
        return true
      end
    end
  end,
}
