-- ================================================================================================
-- title : Native NeoVim Config
-- author: dghuuloc
-- neovim version: NVIM v0.11.5
-- ================================================================================================-------------------------------------------------------------------------------------------------

-- theme
vim.cmd.colorscheme("unokai")
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })

-- Key mappings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.encoding = "utf-8"
vim.opt.syntax = 'on'
vim.opt.termguicolors = true
vim.opt.clipboard = 'unnamedplus'
vim.opt.mouse = 'a'

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 8 

vim.opt.hlsearch = true
vim.opt.smartcase = true
vim.opt.ignorecase = true

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.updatetime = 50
vim.opt.cmdheight = 1

vim.opt.guicursor = {
    'n-v-c:block',        -- normal, visual, command
    'i-ci:ver25',         -- insert
    'r-cr:hor20',         -- replace
    'o:hor50',            -- operator-pending
    'a:blinkwait700-blinkoff400-blinkon250',
}

-- Statusline
vim.opt.laststatus = 3
vim.opt.statusline = "%{%substitute(fnamemodify(bufname('%'),':~:.'),'\\\\','/','g')%} %h%m%r"

-- Buffer navigation
vim.keymap.set('n', '<TAB>', ':bnext<CR>', {noremap = true, silent = true, desc = 'Buffer Next'})
vim.keymap.set('n', '<S-TAB>', ':bprevious<CR>', {noremap = true, silent = true, desc = 'Buffer Previous'})

-- Move lines up/down
-- vim.keymap.set('n', 'K', ':move .-2<CR>==', {noremap = true, silent = true, desc = 'Move line up' })
-- vim.keymap.set('n', 'J', ':move .+1<CR>==', {noremap = true, silent = true, desc = 'Move line down' })
vim.keymap.set('x', 'K', ':move \'<-2<CR>gv-gv', {noremap = true, silent = true, desc = 'Move selection up' })
vim.keymap.set('x', 'J', ':move \'>+1<CR>gv-gv', {noremap = true, silent = true, desc = 'Move selection down' })

-- Get h and l for moving over next lines or previous lines
vim.cmd([[set whichwrap+=<,>,[,],h,l]])

-- Prevent neovim commenting out next line after a comment line
vim.api.nvim_create_autocmd('FileType', {
    pattern = '*',
    callback = function()
        vim.opt_local.formatoptions:remove({ 'r', 'o' })
    end,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
    group = augroup,
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- Set filetype-specific settings
vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = { 'lua', 'java', 'python' },
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = { 'json', 'html', 'css' },
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
    end,
})

-- ================================================================================================
-- lsp
-- ================================================================================================-------------------------------------------------------------------------------------------------
-- Function to find project root
local function find_root(patterns)
    local path = vim.fn.expand('%:p:h')
    local root = vim.fs.find(patterns, { path = path, upward = true })[1]
    return root and vim.fn.fnamemodify(root, ':h') or path
end

-- Shell lsp setup
-- local function setup_shell_lsp() 
--     vim.lsp.start({
--         name = 'bashls',
--         cmd = { 'bash-language-server', 'start' },
--         filetypes = { 'sh', 'bash', 'zsh' },
--         root_dir = find_root({ '.git', 'Makefile' }),
--         settings = {
--             bashIde = {
--                 globPattern = '*@(.sh|.inc|.bash|.command)'
--             }
--         }
--     })
-- end
-- 
-- Python lsp setup
-- local function setup_python_lsp()
--     vim.lsp.start({
--         name = 'pylsp',
--         cmd = { 'pylsp' },
--         filetypes = { 'python' },
--         root_dir = find_root({ 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' }),
--         settings = {
--             pylsp = {
--                 plugins = {
--                     pycodestyle = {
--                         enabled = false
--                     },
--                     flake8 = {
--                         enabled = true
--                     },
--                     black = {
--                         enabled = true
--                     },
--                 }
--             }
--         }
--     })
-- end
-- 
-- Auto-start LSPs based on filetype
-- vim.api.nvim_create_autocmd('FileType', {
--     pattern = 'sh,bash,zsh',
--     callback = setup_shell_lsp,
--     desc = 'Start shell LSP'
-- })
 
-- vim.api.nvim_create_autocmd('FileType', {
--     pattern = 'python',
--     callback = setup_python_lsp,
--     desc = 'Start Python LSP'
-- })

-- LSP keymaps
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(event)
        local opts = { buffer = event.buf }

        -- Navigation
        vim.keymap.set('n', 'gD', vim.lsp.buf.definition, opts)
        vim.keymap.set('n', 'gS', vim.lsp.buf.declaration, opts)
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)

        -- Information
        vim.keymap.set('n', '<C-K>', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
        
        -- Code Actions
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)

        -- Diagnostics
        vim.keymap.set('n', '<leader>nd', vim.diagnostic.goto_next, opts)
        vim.keymap.set('n', '<leader>pd', vim.diagnostic.goto_prev, opts)
        vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, opts)

    end,
})

-- Native Neovim File Explorer (lua)
vim.keymap.set('n', '<leader>E', function()
  require('fexptr-single').toggle()
end, { desc = 'Toggle Native Explorer' })

require("fexptr").setup({})
vim.keymap.set("n", "<leader>e", "<cmd>FexptrToggle<CR>", { noremap = true, silent = true, desc = "Toggle Native Explorer" })

