return {
  "saghen/blink.cmp",
  dependencies = { "saghen/blink.compat" },
  opts = {
    enabled = function()
      return not vim.tbl_contains({ "oil" }, vim.bo.filetype)
        and vim.bo.buftype ~= "prompt"
        and vim.b.completion ~= false
    end,
    sources = {
      default = { "obsidian", "obsidian_new", "obsidian_tags" },
      providers = {
        obsidian = {
          name = "obsidian",
          module = "blink.compat.source",
        },
        obsidian_new = {
          name = "obsidian_new",
          module = "blink.compat.source",
        },
        obsidian_tags = {
          name = "obsidian_tags",
          module = "blink.compat.source",
        },
      },
    },
  },
}
