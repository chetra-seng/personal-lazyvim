return {
  "b0o/SchemaStore.nvim",
  config = function()
    require("lspconfig").yamlls.setup({
      settings = {
        yaml = {
          schemas = {
            ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose.yaml",
            ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/deployment.json"] = {
              "*deployment.yaml",
              "*deploy.yaml",
            },
            ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/service.json"] = {
              "*service.yaml",
              "*svc.yaml",
            },
            ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/ingress.json"] = {
              "*ingress.yaml",
              "*ing.yaml",
            },
            ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/configmap.json"] = {
              "*config.yaml",
              "*cm.yaml",
            },
            ["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/master/secret.json"] = {
              "*secret.yaml",
              "*sec.yaml",
            },
          },
        },
      },
    })
  end,
}
