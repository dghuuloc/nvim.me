require('nvim-tree').setup({
    -- Disable netrw
    disable_netrw = true,
    hijack_netrw = true,

    -- Keep tree root fixed
    respect_buf_cwd = false,        -- do not follow buffer
    sync_root_with_cwd = false,     -- do not sync with Neovim cwd
    update_cwd = false,             -- do not change cwd

    renderer = {
        root_folder_modifier = ":f",
        group_empty = true,         -- collapse empty folders
    },

    update_focused_file = {
        enable = true,              -- highlight current file
        update_cwd = false,         -- do not update cwd
        update_root = false,        -- do not update tree root
    },

    actions = {
        change_dir = {
            enable = false,
            global = false,
            restrict_above_cwd = true,
        },
        open_file = {
            window_picker = { enable = false },
            quit_on_open = false,      -- keep tree open
        },
    },

    hijack_directories = { enable = false },

    filters = { dotfiles = false },

    view = {
        relativenumber =false,
        number = false,
        width = 30,
    },

})

-- Keymapping
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { 
    noremap = true,
    silent = true,
    desc = 'Open or close the tree'
})

vim.opt.statusline = "%{(&filetype=='NvimTree') ? '' : expand('%:t')}"
