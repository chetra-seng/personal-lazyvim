return {
  "b0o/SchemaStore.nvim",
  {
    "neovim/nvim-lspconfig",
    dependencies = { "b0o/SchemaStore.nvim" },
    config = function()
      require("lspconfig").yamlls.setup({
        settings = {
          yaml = {
            schemaStore = {
              enable = true,
              url = "https://www.schemastore.org/api/json/catalog.json",
            },
            schemas = require("schemastore").yaml.schemas({
              extra = {
                {
                  description = "Docker Compose",
                  fileMatch = {
                    "*docker-compose*.yaml",
                    "*docker-compose*.yml",
                  },
                  name = "Docker Compose",
                  url = "https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json",
                },
                {
                  description = "Kubernetes Deployment",
                  fileMatch = {
                    "*deployment.yaml",
                    "*deployment.yml",
                    "*deploy.yaml",
                    "*deploy.yml",
                  },
                  name = "Kubernetes Deployment",
                  url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.30.0/deployment.json",
                },
                {
                  description = "Kubernetes Service",
                  fileMatch = {
                    "*service.yaml",
                    "*service.yml",
                    "*svc.yaml",
                    "*svc.yml",
                  },
                  name = "Kubernetes Service",
                  url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.30.0/service.json",
                },
                {
                  description = "Kubernetes Ingress",
                  fileMatch = {
                    "*ingress.yaml",
                    "*ingress.yml",
                    "*ing.yaml",
                    "*ing.yml",
                  },
                  name = "Kubernetes Ingress",
                  url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.30.0/ingress.json",
                },
                {
                  description = "Kubernetes ConfigMap",
                  fileMatch = {
                    "*configmap.yaml",
                    "*configmap.yml",
                    "*config.yaml",
                    "*config.yml",
                    "*cm.yaml",
                    "*cm.yml",
                  },
                  name = "Kubernetes ConfigMap",
                  url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.30.0/configmap.json",
                },
                {
                  description = "Kubernetes Secret",
                  fileMatch = {
                    "*secret.yaml",
                    "*secret.yml",
                    "*sec.yaml",
                    "*sec.yml",
                  },
                  name = "Kubernetes Secret",
                  url = "https://raw.githubusercontent.com/yannh/kubernetes-json-schema/master/v1.30.0/secret.json",
                },
              },
            }),
          },
        },
      })
    end,
  },
}
