return {
  "b0o/SchemaStore.nvim",
  config = function()
    require("lspconfig").yamlls.setup({
      settings = {
        yaml = {
          schemas = {
            ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose.yaml",
            ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/deployment.json"] = "*deployment.yaml",
            ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/apiservice.json"] = "*service.yaml",
            ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/ingress.json"] = "*ingress.yaml",
          },
        },
      },
    })
  end,
}
