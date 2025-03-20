-------------------------------------------------------------------------------------------------
-- #NEOVIM OPTIONS 
-------------------------------------------------------------------------------------------------
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

vim.opt.scrolloff = 8

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

-------------------------------------------------------------------------------------------------
-- #NEOVIM KEYMAP SETTINGS
-------------------------------------------------------------------------------------------------
vim.keymap.set('n', '<TAB>', ':bnext<CR>', {noremap = true, silent = true, desc = 'Buffer Next'})
vim.keymap.set('n', '<S-TAB>', ':bprevious<CR>', {noremap = true, silent = true, desc = 'Buffer Previous'})

vim.keymap.set('x', 'K', ':move \'<-2<CR>gv-gv', {noremap = true, silent = true})
vim.keymap.set('x', 'J', ':move \'>+1<CR>gv-gv', {noremap = true, silent = true})

vim.keymap.set('v', '<', '<gv', {noremap = true, silent = true})
vim.keymap.set('v', '>', '>gv', {noremap = true, silent = true})

-------------------------------------------------------------------------------------------------
-- #NEOVIM COMMANDS 
-------------------------------------------------------------------------------------------------
-- Set up colorscheme
vim.cmd.colorscheme('nord')

-- Get h and l for moving over next lines or previous lines
vim.cmd([[set whichwrap+=<,>,[,],h,l]])

-- Prevent neovim commenting out next line after a comment line
vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
        vim.opt_local.formatoptions:remove({ "r", "o" })
    end,
})

-------------------------------------------------------------------------------------------------
-- #BOOTSTRAP PLUGIN MANAGER
-------------------------------------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })

end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
    {	
		"williamboman/mason.nvim",
		config = function()
			require('mason').setup()
		end
        --[[
            :MasonInstall jdtls java-debug-adapter js-debug-adapter 
        ]]
    },

    {
        "mfussenegger/nvim-jdtls"
    },
	
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            "rcarriga/nvim-dap-ui",
            "nvim-neotest/nvim-nio",
            "mfussenegger/nvim-dap-python",
        }
    },
})

