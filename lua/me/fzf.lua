-- fzf-lua
vim.pack.add({
  { src = "https://github.com/ibhagwan/fzf-lua" }
})

local status_ok, fzf = pcall(require, "fzf-lua")
if not status_ok then
  vim.schedule(function()
    vim.notify("fzf-lua is not ready yet. Restart Neovim once after vim.pack installs it.", vim.log.levels.INFO)
  end)
  return
end

fzf.setup({})

-- set a vim motion to search for files by their names
vim.keymap.set("n", "<leader>ff", require("fzf-lua").files, {desc = "[F]zf [F]iles"})
-- set a vim motion to search for files based on the text inside of them
vim.keymap.set("n", "<leader>fg", require("fzf-lua").live_grep, {desc = "[F]ind by [G]rep"})
-- set a vim motion to search Open Buffers
vim.keymap.set("n", "<leader>fb", require("fzf-lua").buffers, { desc = '[F]ind Existing [B]uffers' })

