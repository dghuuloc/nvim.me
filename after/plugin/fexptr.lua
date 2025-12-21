require("fexptr").setup({
    width = 35,
    show_hidden = false,
    -- icons = {
    --     folder_closed = "",
    --     folder_open   = "",
    --     file          = "",
    -- },
})
vim.keymap.set("n", "<leader>e", "<cmd>FexptrToggle<CR>", { noremap = true, silent = true, desc = "Toggle Native Explorer" })
