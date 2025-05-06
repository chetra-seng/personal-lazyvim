return {
  "Exafunction/codeium.nvim",
  enabled = true,
  opts = {
    quiet = true,
    enable_cmp_source = false,
    virtual_text = {
      enabled = true,
      key_bindings = {
        accept = false, -- handled by nvim-cmp / blink.cmp
        next = "<M-]>",
        prev = "<M-[>",
      },
    },
  },
}
