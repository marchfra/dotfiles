return {
  "nvim-lspconfig",
  opts = {
    ---@type lspconfig.options
    servers = {
      pyright = {
        -- mason = false, --set this to true when switching to Astral's ty
      },
    },
  },
}
