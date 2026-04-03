require("fexptr").setup({
    width = 35,
    show_hidden = false,

    folder_indicators = {
        open = "▾",
        closed = "▸",
    },

    icons = {
        folder_open = "",
        folder_closed = "",
        file = "󰈙",
    },
    -- icons = {
    --     folder_closed = "",
    --     folder_open   = "",
    --     file          = "",
    -- },
})

vim.keymap.set("n", "<leader>e", "<cmd>FexptrToggle<CR>", { noremap = true, silent = true, desc = "Toggle Native Explorer" })
