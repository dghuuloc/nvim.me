-- ================================================================================================
-- title : Native NeoVim Config
-- author: dghuuloc
-- neovim version: NVIM v0.12.4
-- Place this file at:
--  Linux/macOS/WSL: ~/.config/nvim/init.lua
--  Windows:         ~/AppData/Local/nvim/init.lua
-- ================================================================================================

-- local config = vim.fn.stdpath("config")
--
-- vim.cmd.source(vim.fs.joinpath(config, "options.vim"))
-- vim.cmd.source(vim.fs.joinpath(config, "mappings.vim"))
-- dofile(vim.fs.joinpath(config, "commands.lua"))
-- dofile(vim.fs.joinpath(config, "fugitive.lua"))

-- vim.cmd(string.format([[
--   source %s
--   source %s
-- ]], vim.fs.joinpath(config, "options.vim"), vim.fs.joinpath(config, "mappings.vim")))

-- dofile(vim.fs.joinpath(config, "commands.lua"))

if vim.fn.has('nvim-0.12') == 0 then
  error('This configuration requires Neovim 0.12 or newer')
end

-- ================================================================================================
-- #key mappings
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.hidden = true                       -- allow hidden buffers
vim.opt.errorbells = false                  -- no error sounds
vim.opt.backspace = "indent,eol,start"      -- better backspace behaviour
vim.opt.autochdir = false                   -- do not autochange directories
vim.opt.selection = "inclusive"             -- include last char in selection
vim.opt.encoding = "utf-8"                  -- set encoding
-- vim.opt.syntax = 'on'                       -- nvim-treesitter replaces it
vim.opt.clipboard:append('unnamedplus')     -- use system clipboard
vim.opt.iskeyword:append("-")               -- include - in words
vim.opt.path:append("**")                   -- include subdirs in search
vim.opt.isfname:append("@-@")

vim.opt.mouse = 'a'                         -- enable mouse support

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

vim.opt.tabstop = 2                         -- how many spaces tab inserts
vim.opt.shiftwidth = 2                      -- controls number of spaces when using >> or << commands
vim.opt.softtabstop = 2                     -- how many spaces tab inserts
vim.opt.expandtab = true                    -- use spaces instead of tabs
vim.opt.smartindent = true                  -- indenting correctly after {
vim.opt.autoindent = true                     -- copy indent from current line when starting new line

vim.opt.scrolloff = 10                      -- keep 10 lines above/below cursor
vim.opt.sidescrolloff = 10                  -- keep 10 lines to left/right of cursor

vim.opt.ignorecase = true                   -- case insensitive search
vim.opt.smartcase = true                    -- case sensitive if uppercase in string
vim.opt.hlsearch = true                     -- highlight search matches
vim.opt.incsearch = true                    -- show matches as you type

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.wrap = false                        -- do not wrap lines by default
vim.opt.breakindent = true                  -- prevent line wrapping
vim.opt.swapfile = false                    -- do not create a swapfile
vim.opt.writebackup = false                 -- do not write to a backup file
vim.opt.updatetime = 50                     -- faster completion
vim.opt.cmdheight = 1                       -- single line command line
vim.opt.whichwrap:append("<,>,[,],h,l")     -- Get h and l for moving over next lines or previous lines

vim.opt.undofile  = true                    -- persist undo history across sessions
vim.opt.undodir   = vim.fn.stdpath("data") .. "/undodir"

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

-- Disable Space bar since it will be used as the leader key
vim.keymap.set({ "n", "v" }, "<leader>", "<nop>")

-- Buffer navigation
vim.keymap.set('n', '<TAB>', ':bnext<CR>', {noremap = true, silent = true, desc = 'Buffer Next'})
vim.keymap.set('n', '<S-TAB>', ':bprevious<CR>', {noremap = true, silent = true, desc = 'Buffer Previous'})

-- Move lines up/down
-- vim.keymap.set('n', 'K', ':move .-2<CR>==', {noremap = true, silent = true, desc = 'Move line up' })
-- vim.keymap.set('n', 'J', ':move .+1<CR>==', {noremap = true, silent = true, desc = 'Move line down' })
vim.keymap.set('x', 'K', ':move \'<-2<CR>gv-gv', {noremap = true, silent = true, desc = 'Move selection up' })
vim.keymap.set('x', 'J', ':move \'>+1<CR>gv-gv', {noremap = true, silent = true, desc = 'Move selection down' })

-- after a search, press escape to clear highlights
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "clear search highlight" })

-- Little one from Primeagen to mass replace string in a file
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { silent = false, desc = "Replace word cursor is on globally" }
)

vim.keymap.set("n", "<leader>re", "<cmd>restart<cr>",
  { noremap = true, silent = true, desc = "Restart config :restart)" }
)

-- Paste without replacing paste with what you are highlighted over
vim.keymap.set("n", "<leader>p", '"_dP')

-- Exit terminal with Esc
vim.keymap.set("t", "<Esc>", "<C-\\><C-N>")

-- Built-in Neovim 0.12 undo-tree plugin.
vim.keymap.set('n', '<leader>u', function()
  vim.cmd.packadd('nvim.undotree')
  vim.cmd.Undotree()
end, { noremap = true, silent = true, desc = 'Toggle undo tree' })


-- ── Installl plugins using vim.pack.add({*}) ────────────────────────────────
vim.pack.add({

  --- #Fexptr file explorer
  { src = "https://github.com/dghuuloc/fexptr.nvim" },

  --- #Colorscheme
  {
    src = "https://github.com/sainnhe/gruvbox-material",
    name = "gruvbox-material",
  },

  --- #Treesitter
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
    version = "main",
    build = ":TSUpdate"
  },

  --- #Fuzzy finder
  -- { src = "https://github.com/ibhagwan/fzf-lua" },

  --- #Mini
  { src = "https://github.com/nvim-mini/mini.nvim" },

  --- #Git
  -- { src = "https://github.com/lewis6991/gitsigns.nvim" },
  -- { src = "https://github.com/tpope/vim-fugitive" },

  --- #Mason
  -- { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/mason-org/mason.nvim" },

  -- {
  --   src     = "https://github.com/saghen/blink.cmp",
  --   version = vim.version.range("1.*"),
  -- },
  -- { src = "https://github.com/L3MON4D3/LuaSnip" },
  -- { src = "https://github.com/rafamadriz/friendly-snippets" },

  -- #Formatting + Linting
  -- { src = "https://github.com/stevearc/conform.nvim" },
  -- { src = "https://github.com/mfussenegger/nvim-lint" },

  --- #Java (jdtls)
  { src = "https://github.com/mfussenegger/nvim-jdtls" },

  --- #DAP (debugging)
  { src = "https://github.com/mfussenegger/nvim-dap" },
  { src = "https://github.com/mfussenegger/nvim-dap-python" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },

  --- # Markdown Preview
  -- { src = "https://github.com/OXY2DEV/markview.nvim" },

  --- #AI
  -- { src = "https://github.com/zbirenbaum/copilot.lua" },
  -- { src = "https://github.com/CopilotC-Nvim/CopilotChat.nvim" },
  -- {
  --     src   = "https://github.com/olimorris/codecompanion.nvim",
  --     deps  = {
  --         { src = "https://github.com/nvim-lua/plenary.nvim" },
  --         { src = "https://github.com/stevearc/dressing.nvim" },
  --         {
  --             src  = "https://github.com/MeanderingProgrammer/render-markdown.nvim",
  --             ft   = { "markdown","codecompanion" },
  --         },
  --     },
  -- },

  --- #Misc
  -- { src = "https://github.com/nvim-lua/plenary.nvim" },
  -- { src = "https://github.com/folke/todo-comments.nvim" },
})

-- ── Plugin's config dependecies ─────────────────────────────
require("me.autocmds")
require("me.mini")
require("me.lsp")
require("me.nts")
-- require("me.gitsigns")
require("me.dap")

-- ── Gruvbox Material Colorscheme ─────────────────────────────
vim.opt.background = "dark"
vim.opt.termguicolors = true

vim.g.gruvbox_material_background = "hard"
vim.g.gruvbox_material_foreground = "original"
vim.g.gruvbox_material_enable_bold = 1
vim.g.gruvbox_material_enable_italic = 1
vim.g.gruvbox_material_better_performance = 1

local loaded, err = pcall(function()
  vim.cmd("silent colorscheme gruvbox-material")
end)

if not loaded then
  vim.notify(
    "Failed to load gruvbox-material:\n" .. tostring(err),
    vim.log.levels.ERROR
  )

  vim.cmd.colorscheme("unokai")
end

-- ── fexptr file explorer ──────────────────────────────────────────────────────
local ok_fex, fex = pcall(require, "fexptr")
if ok_fex then
  fex.setup({
    width           = 25,
    show_hidden     = true,
    folder_indicators = { open = "▾", closed = "▸" },
    -- icons = { folder_open = "", folder_closed = "", file = "󰈙" },
    icons = {
      folder_closed = "",
      folder_open   = "",
      file          = "󰈙",
    },
  })

  vim.keymap.set("n","<leader>e","<cmd>FexptrToggle<CR>",
  { noremap=true, silent=true, desc="toggle file explorer" })
end

