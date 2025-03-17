---[[ NEOVIM KEYMAPPINGS ]]
vim.keymap.set('n', '<TAB>', ':bnext<CR>', {noremap = true, silent = true, desc = "Buffer Next"})
vim.keymap.set('n', '<S-TAB>', ':bprevious<CR>', {noremap = true, silent = true, desc = "Buffer Previous"})

vim.keymap.set('x', 'K', ':move \'<-2<CR>gv-gv', {noremap = true, silent = true})
vim.keymap.set('x', 'J', ':move \'>+1<CR>gv-gv', {noremap = true, silent = true})
