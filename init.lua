-- ================================================================================================
-- title : Native NeoVim Config
-- author: dghuuloc
-- neovim version: NVIM v0.12.0
-- ================================================================================================

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
-- vim.cmd([[set whichwrap+=<,>,[,],h,l]])

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

-- #autocmds
-- prevent neovim commenting out next line after a comment line
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("no_auto_comment", {}),
    pattern = "*",
	callback = function()
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- Highlight yanked text
vim.api.nvim_create_autocmd('TextYankPost', {
    group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
    pattern = "*",
    desc = "highlight selection on yank",
    callback = function()
        vim.highlight.on_yank({ timeout = 200, visual = true })
    end,
})

-- Set filetype-specific settings
vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'lua', 'java', 'python' },
    callback = function()
        vim.opt_local.tabstop = 4
        vim.opt_local.shiftwidth = 4
    end,
})

vim.api.nvim_create_autocmd('FileType', {
    pattern = { 'json', 'html', 'css' },
    callback = function()
        vim.opt_local.tabstop = 2
        vim.opt_local.shiftwidth = 2
    end,
})

-- auto resize splits when the terminal's window is resized
vim.api.nvim_create_autocmd("VimResized", {
	command = "wincmd =",
})


-- restore cursor to file position in previous editing session
vim.api.nvim_create_autocmd("BufReadPost", {
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			vim.api.nvim_win_set_cursor(0, mark)
			-- defer centering slightly so it's applied after render
			vim.schedule(function()
				vim.cmd("normal! zz")
			end)
		end
	end,
})

-- syntax highlighting for dotenv files
vim.api.nvim_create_autocmd("BufRead", {
	group = vim.api.nvim_create_augroup("dotenv_ft", { clear = true }),
	pattern = { ".env", ".env.*" },
	callback = function()
		vim.bo.filetype = "dosini"
	end,
})

-- #vim.pack.add plugins
require("me.fzf")
require("me.mini")
require("me.gitsigns")
require("me.lsp")

-- colorscheme
vim.pack.add({
    { src = "https://github.com/folke/tokyonight.nvim" },
})
local ok, tokyonight = pcall(require, "tokyonight")
if ok then
    tokyonight.setup({ style = "storm" })
     pcall(vim.cmd.colorscheme, "tokyonight")
else
    vim.cmd.colorscheme("catppuccin")
end
-- vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
-- vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
-- vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })

-- fexptr.nvim
vim.pack.add({
    { src = "https://github.com/dghuuloc/fexptr.nvim" },
})

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

-- nvim-treesitter
vim.pack.add({
    {
        src = "https://github.com/nvim-treesitter/nvim-treesitter",
        version = "main",
        build = ":TSUpdate"
    }
})

-- #floating terminal
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
		vim.fn.termopen(os.getenv("SHELL"))
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
