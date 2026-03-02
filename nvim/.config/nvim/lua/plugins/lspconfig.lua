return {
  "nvim-lspconfig",
  opts = {
    ---@type lspconfig.options
    servers = {
      pyright = {
        mason = false, --set this to false when switching to Astral's ty
        autostart = false,
      },
    },
  },
}
