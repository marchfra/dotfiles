-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Set the textwidth to 88 for Python files
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.py",
  command = "setlocal textwidth=88",
})

vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.py",
  callback = function()
    -- Organize imports
    vim.lsp.buf.code_action({
      context = {
        only = { "source.organizeImports" },
        diagnostics = {},
      },
      apply = true,
    })

    -- Fix all
    vim.lsp.buf.code_action({
      context = {
        only = { "source.fixAll" },
        diagnostics = {},
      },
      apply = true,
    })
  end,
})

-- -- Autosave on focus lost
-- vim.api.nvim_create_autocmd("FocusLost", {
--   callback = function()
--     vim.cmd("write")
--   end,
-- })
