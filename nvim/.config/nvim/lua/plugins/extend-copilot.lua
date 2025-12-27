return {
  "zbirenbaum/copilot.lua",
  config = function()
    local copilot_enabled = true

    local function toggle_copilot()
      if copilot_enabled then
        vim.cmd("Copilot disable")
        copilot_enabled = false
        vim.notify("Copilot completions disabled", vim.log.levels.INFO)
      else
        vim.cmd("Copilot enable")
        copilot_enabled = true
        vim.notify("Copilot completions enabled", vim.log.levels.INFO)
      end
    end

    vim.keymap.set("n", "<leader>at", toggle_copilot, { desc = "Toggle Copilot Completions" })
  end,
}
