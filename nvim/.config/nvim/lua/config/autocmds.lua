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

-- Automatically commit lockfile after running Lazy Update (or Sync)
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyUpdate",
  callback = function()
    local config_dir = vim.fn.resolve(vim.fn.stdpath("config"))
    local repo_dir = config_dir:gsub("/nvim/%.config/nvim$", "")

    if repo_dir == config_dir then
      repo_dir = (vim.env.HOME or "") .. "/dotfiles"
    end

    local lockfile = repo_dir .. "/nvim/.config/nvim/lazy-lock.json"

    local cmd = {
      "git",
      "-C",
      repo_dir,
      "commit",
      lockfile,
      "-m",
      "Update lazy-lock.json",
    }

    local success, process = pcall(function()
      return vim.system(cmd):wait()
    end)

    if process and process.code == 0 then
      vim.notify("Committed lazy-lock.json")
      vim.notify(process.stdout)
    else
      if not success then
        vim.notify("Failed to run command '" .. table.concat(cmd, " ") .. "':", vim.log.levels.WARN, {})
        vim.notify(tostring(process), vim.log.levels.WARN, {})
      else
        vim.notify("git ran but failed to commit:")
        vim.notify(process.stdout, vim.log.levels.WARN, {})
      end
    end
  end,
})
