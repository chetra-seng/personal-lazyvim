return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      window = {
        mappings = {
          ["<leader>p"] = {
            "image_wezterm",
            desc = "Explorer preview image",
          },
        },
      },
      commands = {
        image_wezterm = function(state)
          local node = state.tree:get_node()
          if node.type == "file" then
            require("image_preview").PreviewImage(node.path)
          end
        end,
      },
    },
  },
}
