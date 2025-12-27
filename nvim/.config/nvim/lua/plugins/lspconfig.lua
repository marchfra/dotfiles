return {
  "nvim-lspconfig",
  opts = {
    ---@type lspconfig.options
    servers = {
      pyright = {

        -- -- ChagGPT config that should turn off everything except hover
        -- on_attach = function(client, _)
        --   -- Disable everything except hover
        --   for capability, _ in pairs(client.server_capabilities) do
        --     client.server_capabilities[capability] = false
        --   end
        --   client.server_capabilities.hoverProvider = true
        --   client.server_capabilities.renameProvider = true
        -- end,
        -- settings = {
        --   python = {
        --     analysis = {
        --       diagnosticMode = "off",
        --       typeCheckingMode = "off",
        --     },
        --   },
        -- },

        -- My old configuration
        capabilities = (function()
          local capabilities = vim.lsp.protocol.make_client_capabilities()
          capabilities.textDocument.publishDiagnostics.tagSupport.valueSet = { 2 }
          return capabilities
        end)(),
        settings = {
          python = {
            analysis = {
              useLibraryCodeForTypes = true,
              diagnosticSeverityOverrides = {
                reportUnusedVariable = "none", -- disabled
              },
              typeCheckingMode = "basic",
            },
          },
        },
      },
      ruff = {
        on_attach = function(client, _)
          client.server_capabilities.hoverProvider = false
        end,
      },
    },
  },
}
