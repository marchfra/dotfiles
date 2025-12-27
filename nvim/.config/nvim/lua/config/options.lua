-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Set tabs to 4 spaces
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.formatoptions = vim.opt.formatoptions - "t" -- Disable auto-wrap while typing
vim.opt.formatoptions = vim.opt.formatoptions - "o" -- Disable autocomment when hitting 'o' or 'O' in Normal mode
