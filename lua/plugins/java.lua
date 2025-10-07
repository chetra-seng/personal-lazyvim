return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      -- remove the old lombok arg if present
      for i, arg in ipairs(opts.cmd or {}) do
        if arg:match("lombok.jar") then
          table.remove(opts.cmd, i)
        end
      end

      -- add your custom lombok path
      local lombok_jar = vim.fn.expand("$MASON/share/lombok-nightly/lombok.jar")
      table.insert(opts.cmd, string.format("--jvm-arg=-javaagent:%s", lombok_jar))

      return opts
    end,
  },
}
