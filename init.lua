-- ================================================================================================
-- title : Native NeoVim Config
-- author: dghuuloc
-- neovim version: NVIM v0.12.0
-- ================================================================================================

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
--
-- dofile(vim.fs.joinpath(config, "commands.lua"))

-- #theme
-- vim.cmd.colorscheme("catppuccin")
vim.opt.termguicolors = true

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
vim.opt.syntax = 'off'                      -- nvim-treesitter replaces it
vim.opt.clipboard = 'unnamedplus'           -- use system clipboard
vim.opt.mouse = 'a'                         -- enable mouse support

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

vim.opt.tabstop = 4                         -- how many spaces tab inserts
vim.opt.shiftwidth = 4                      -- controls number of spaces when using >> or << commands
vim.opt.softtabstop = 4                     -- how many spaces tab inserts
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
vim.diagnostic.config({ virtual_text = true }) -- inline diagnostics

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
-- vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { silent = false })

-- Paste without replacing paste with what you are highlighted over
vim.keymap.set("n", "<leader>p", '"_dP')

-- Exit terminal with Esc
vim.keymap.set("t", "<Esc>", "<C-\\><C-N>")

-- ── Installl plugins using vim.pack.add(*) ────────────────────────────────
vim.pack.add({

    -- #Colorscheme
    { src = "https://github.com/folke/tokyonight.nvim" },

    -- #Fexptr file explorer
    { src = "https://github.com/dghuuloc/fexptr.nvim" },

    -- #Machine Learning / Deep Learning
    { src = "https://github.com/dghuuloc/mlbuddy.nvim" },

    -- #Treesitter
    {
        src = "https://github.com/nvim-treesitter/nvim-treesitter",
        version = "main",
        build = ":TSUpdate"
    },

    -- #Fuzzy finder
    { src = "https://github.com/ibhagwan/fzf-lua" },

    -- #Editing helpers
    { src = "https://github.com/nvim-mini/mini.nvim" },

    -- #Git
    { src = "https://github.com/lewis6991/gitsigns.nvim" },
    { src = "https://github.com/tpope/vim-fugitive" },

    -- #LSP + Completion
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/mason-org/mason.nvim" },
    {
      src     = "https://github.com/saghen/blink.cmp",
      version = vim.version.range("1.*"),
    },
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/rafamadriz/friendly-snippets" },

    -- #Formatting + Linting
    { src = "https://github.com/stevearc/conform.nvim" },
    { src = "https://github.com/mfussenegger/nvim-lint" },

    -- #Java (jdtls)
    { src = "https://github.com/mfussenegger/nvim-jdtls" },

    -- #DAP (debugging)
    { src = "https://github.com/mfussenegger/nvim-dap" },
    { src = "https://github.com/mfussenegger/nvim-dap-python" },
    { src = "https://github.com/rcarriga/nvim-dap-ui" },
    { src = "https://github.com/nvim-neotest/nvim-nio" },
    { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },

    -- # Markdown/Asciidoc
    { src = "https://github.com/OXY2DEV/markview.nvim" },
    { src = "https://github.com/dghuuloc/asciidoc.nvim" },

    -- #AI
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

    -- #Misc
    -- { src = "https://github.com/nvim-lua/plenary.nvim" },
    -- { src = "https://github.com/folke/todo-comments.nvim" },

})

-- ── Plugin's configs ────────────────────────────────────────
require("me.autocmds")
require("me.fzf")
require("me.mini")
require("me.gitsigns")
require("me.lsp")
require("me.dap")
require("me.preview")

-- ── Tokyonight Colorscheme ──────────────────────────────────────────────────────
local ok, tokyonight = pcall(require, "tokyonight")
if ok then
    tokyonight.setup({ style = "storm" })
     pcall(vim.cmd.colorscheme, "tokyonight")
-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
-- vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
-- vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
else
    vim.cmd.colorscheme("catppuccin")
end

-- ── fexptr file explorer ──────────────────────────────────────────────────────
local ok_fex, fex = pcall(require, "fexptr")
if ok_fex then
    fex.setup({
        width           = 35,
        show_hidden     = false,
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

-- ── nvim-treesitter ──────────────────────────────────────────────────────
vim.pack.add({
})

local ok, nts = pcall(require, "nvim-treesitter")
if not ok then
    return
end

nts.setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
})

local parsers = {
    "vim", "vimdoc", "markdown", "markdown_inline",
    "java", "python", "typescript", "javascript", "rust", "lua", "sql",
    "tsx", "html", "css", "query", "dockerfile",
    "json", "yaml", "toml", "bash"
}

vim.api.nvim_create_user_command("TSInstallMyParsers", function()
    nts.install(parsers)
end, { desc = "Install my Treesitter parsers" })

local group = vim.api.nvim_create_augroup("MyTreeSitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "*",

    callback = function(ev)
        local ft = vim.bo[ev.buf].filetype
        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
            return
        end

        local ok_lang = vim.treesitter.language.add(lang)
        if not ok_lang then
            return
        end

        if vim.treesitter.query.get(lang, "highlights") then
            pcall(vim.treesitter.start, ev.buf, lang)
        end

        -- if vim.treesitter.query.get(lang, "folds") then
        --   vim.wo[0].foldmethod = "expr"
        --   vim.wo[0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        -- end

        if vim.treesitter.query.get(lang, "indents") then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,

})
-- ── mlbuddy ────────────────────────────────────────────────────────────────
local ok_mlb, mlbuddy = pcall(require, "mlbuddy")
if ok_mlb then
  mlbuddy.setup({
    debugger = {
      enabled       = true,
      auto_inspect  = false,
      virt_text     = false,
      default_model = "full"
    },
    dataloader = {
      enabled       = true,
      auto_inspect  = false,
    },
  })

  require("me.ml").apply("code")

  vim.keymap.set("n", "<leader>mc", function()
    require("me.ml").apply("code")
  end, { desc = "Normal Python DAP mode" })

  vim.keymap.set("n", "<leader>mm", function()
    require("me.ml").apply("model")
  end, { desc = "ML model mode" })

  vim.keymap.set("n", "<leader>mt", function()
    require("me.ml").toggle()
  end, { desc = "Toggle ML debug mode" })

end

-- ── floating terminal ──────────────────────────────────────────────────────
vim.api.nvim_create_autocmd("TermClose", {
	callback = function()
		if vim.v.event.status == 0 then
			vim.api.nvim_buf_delete(0, {})
		end
	end,
})

vim.api.nvim_create_autocmd("TermOpen", {
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.opt_local.signcolumn = "no"
	end,
})

local terminal_state = { buf = nil, win = nil, is_open = false }

local function FloatingTerminal()
	if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
		vim.api.nvim_win_close(terminal_state.win, false)
		terminal_state.is_open = false
		return
	end

	if not terminal_state.buf or not vim.api.nvim_buf_is_valid(terminal_state.buf) then
		terminal_state.buf = vim.api.nvim_create_buf(false, true)
		vim.bo[terminal_state.buf].bufhidden = "hide"
	end

	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	terminal_state.win = vim.api.nvim_open_win(terminal_state.buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})

	vim.wo[terminal_state.win].winblend = 0
	vim.wo[terminal_state.win].winhighlight = "Normal:FloatingTermNormal,FloatBorder:FloatingTermBorder"
	vim.api.nvim_set_hl(0, "FloatingTermNormal", { bg = "none" })
	vim.api.nvim_set_hl(0, "FloatingTermBorder", { bg = "none" })

	local has_terminal = false
	local lines = vim.api.nvim_buf_get_lines(terminal_state.buf, 0, -1, false)
	for _, line in ipairs(lines) do
		if line ~= "" then
			has_terminal = true
			break
		end
	end
	if not has_terminal then
        vim.fn.jobstart(os.getenv("SHELL") or "sh", { term = true })
	end

	terminal_state.is_open = true
	vim.cmd("startinsert")

	vim.api.nvim_create_autocmd("BufLeave", {
		buffer = terminal_state.buf,
		callback = function()
			if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
				vim.api.nvim_win_close(terminal_state.win, false)
				terminal_state.is_open = false
			end
		end,
		once = true,
	})
end

vim.keymap.set("n", "<leader>t", FloatingTerminal, { noremap = true, silent = true, desc = "Toggle floating terminal" })
vim.keymap.set("t", "<Esc>", function()
	if terminal_state.is_open and terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
		vim.api.nvim_win_close(terminal_state.win, false)
		terminal_state.is_open = false
	end
end, { noremap = true, silent = true, desc = "Close floating terminal" })
