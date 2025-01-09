return {
  "danymat/neogen",
  keys = {
    {
      "<leader>cn",
      function()
        local options = {
          { value = "func", desc = "Function annotation" },
          { value = "class", desc = "Class annotation" },
          { value = "type", desc = "Type annotation" },
          { value = "file", desc = "File annotation" },
        }

        local items = {}

        for _, option in ipairs(options) do
          table.insert(items, option.value .. " - " .. option.desc)
        end

        vim.ui.select(items, {
          prompt = "Select annotation type:",
        }, function(selected, i)
          if selected then
            require("neogen").generate({ type = options[i].value })
          else
            print("No annotation type selected")
          end
        end)
      end,
      desc = "Generate Neogen annotations",
    },
  },
}
