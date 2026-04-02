-- ================================================================================================
-- title : Native NeoVim Config
-- author: dghuuloc
-- neovim version: NVIM v0.12.0
-- ================================================================================================

-- #theme
vim.cmd.colorscheme("unokai")
vim.opt.termguicolors = true                 
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })

-- #key mappings 
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.hidden = true                       -- allow hidden buffers
vim.opt.errorbells = false                  -- no error sounds
vim.opt.backspace = "indent,eol,start"      -- better backspace behaviour
vim.opt.autochdir = false                   -- do not autochange directories
vim.opt.iskeyword:append("-")               -- include - in words
vim.opt.path:append("**")                   -- include subdirs in search
vim.opt.selection = "inclusive"             -- include last char in selection
vim.opt.encoding = "utf-8"                  -- set encoding
vim.opt.syntax = 'on'
vim.opt.clipboard = 'unnamedplus'           -- use system clipboard
vim.opt.mouse = 'a'                         -- enable mouse support

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

vim.opt.tabstop = 4                         -- tabwidth
vim.opt.shiftwidth = 4                      -- indent width
vim.opt.softtabstop = 4                     -- soft tab stop not tabs or tab/backspace
vim.opt.expandtab = true                    -- use spaces instead of tabs
vim.opt.smartindent = true                  -- smart auto-indent

vim.opt.scrolloff = 10                      -- keep 10 lines above/below cursor
vim.opt.sidescrolloff = 10                  -- keep 10 lines to left/right of cursor

vim.opt.ignorecase = true                   -- case insensitive search
vim.opt.smartcase = true                    -- case sensitive if uppercase in string
vim.opt.hlsearch = true                     -- highlight search matches
vim.opt.incsearch = true                    -- show matches as you type

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.wrap = false                        -- do not wrap lines by default
vim.opt.swapfile = false                    -- do not create a swapfile
vim.opt.writebackup = false                 -- do not write to a backup file
vim.opt.updatetime = 50                     -- faster completion
vim.opt.cmdheight = 1                       -- single line command line

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
vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
        vim.opt_local.formatoptions:remove({ "r", "o" })
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

-- Function to find project root
local function find_root(patterns)
    local path = vim.fn.expand('%:p:h')
    local root = vim.fs.find(patterns, { path = path, upward = true })[1]
    return root and vim.fn.fnamemodify(root, ':h') or path
end

-- #vim.pack
-- vim.pack.add({
--     { src = "https://github.com/dghuuloc/fexptr.nvim" }
-- })

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

-- #LSP keymaps
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
