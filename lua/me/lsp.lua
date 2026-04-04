-- Language Server Protocols
vim.pack.add({
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/mason-org/mason.nvim" },
    -- { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
    { src = "https://github.com/saghen/blink.cmp",
		version = vim.version.range("1.*"),
    },
    { src = "https://github.com/L3MON4D3/LuaSnip" }
})

require("mason").setup({})

local diagnostic_signs = {
	Error = " ",
	Warn = " ",
	Hint = "",
	Info = "",
}

vim.diagnostic.config({
	virtual_text = { prefix = "●", spacing = 4 },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
			[vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
			[vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
			[vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = "always",
		header = "",
		prefix = "",
		focusable = false,
		style = "minimal",
	},
})

do
	local orig = vim.lsp.util.open_floating_preview
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig(contents, syntax, opts, ...)
	end
end

local function lsp_on_attach(ev)
	local client = vim.lsp.get_client_by_id(ev.data.client_id)
	if not client then
		return
	end

	local bufnr = ev.buf
	local opts = { noremap = true, silent = true, buffer = bufnr }

	vim.keymap.set("n", "<leader>gd", function()
		require("fzf-lua").lsp_definitions({ jump_to_single_result = true })
	end, opts)

	vim.keymap.set("n", "<leader>gD", vim.lsp.buf.definition, opts)

	vim.keymap.set("n", "<leader>gS", function()
		vim.cmd("vsplit")
		vim.lsp.buf.definition()
	end, opts)

	vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

	vim.keymap.set("n", "<leader>D", function()
		vim.diagnostic.open_float({ scope = "line" })
	end, opts)
	vim.keymap.set("n", "<leader>d", function()
		vim.diagnostic.open_float({ scope = "cursor" })
	end, opts)
	vim.keymap.set("n", "<leader>nd", function()
		vim.diagnostic.jump({ count = 1 })
	end, opts)

	vim.keymap.set("n", "<leader>pd", function()
		vim.diagnostic.jump({ count = -1 })
	end, opts)

	vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

	vim.keymap.set("n", "<leader>fd", function()
		require("fzf-lua").lsp_definitions({ jump_to_single_result = true })
	end, opts)
	vim.keymap.set("n", "<leader>fr", function()
		require("fzf-lua").lsp_references()
	end, opts)
	vim.keymap.set("n", "<leader>ft", function()
		require("fzf-lua").lsp_typedefs()
	end, opts)
	vim.keymap.set("n", "<leader>fs", function()
		require("fzf-lua").lsp_document_symbols()
	end, opts)
	vim.keymap.set("n", "<leader>fw", function()
		require("fzf-lua").lsp_workspace_symbols()
	end, opts)
	vim.keymap.set("n", "<leader>fi", function()
		require("fzf-lua").lsp_implementations()
	end, opts)

	if client:supports_method("textDocument/codeAction", bufnr) then
		vim.keymap.set("n", "<leader>oi", function()
			vim.lsp.buf.code_action({
				context = { only = { "source.organizeImports" }, diagnostics = {} },
				apply = true,
				bufnr = bufnr,
			})
			vim.defer_fn(function()
				vim.lsp.buf.format({ bufnr = bufnr })
			end, 50)
		end, opts)
	end
end

vim.api.nvim_create_autocmd("LspAttach", { group = augroup, callback = lsp_on_attach })

vim.keymap.set("n", "<leader>q", function()
	vim.diagnostic.setloclist({ open = true })
end, { desc = "Open diagnostic list" })
vim.keymap.set("n", "<leader>dl", vim.diagnostic.open_float, { desc = "Show line diagnostics" })

require("blink.cmp").setup({
	keymap = {
		preset = "none",
		["<C-Space>"] = { "show", "hide" },
		["<CR>"] = { "accept", "fallback" },
		["<C-j>"] = { "select_next", "fallback" },
		["<C-k>"] = { "select_prev", "fallback" },
		["<Tab>"] = { "snippet_forward", "fallback" },
		["<S-Tab>"] = { "snippet_backward", "fallback" },
	},
	appearance = { nerd_font_variant = "mono" },
	completion = { menu = { auto_show = true } },
	sources = { default = { "lsp", "path", "buffer", "snippets" } },
	snippets = {
		expand = function(snippet)
			require("luasnip").lsp_expand(snippet)
		end,
	},

	fuzzy = {
		implementation = "prefer_rust",
		prebuilt_binaries = { download = true },
	},
})

vim.lsp.config["*"] = {
	capabilities = require("blink.cmp").get_lsp_capabilities(),
}

vim.lsp.config("lua_ls", {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			telemetry = { enable = false },
		},
	},
})

vim.lsp.config("pyright", {})
vim.lsp.config("ts_ls", {})

vim.lsp.enable({
	"lua_ls",
	"pyright",
	"ts_ls"
})

-- ~/.config/nvim-new/lsp/lua_ls.lua
---@type vim.lsp.Config
-- return {
--     cmd = { 'lua-language-server' },
--     filetypes = { 'lua' },
--     root_markers = {
--         '.luarc.json',
--         '.luarc.jsonc',
--         '.luacheckrc',
--         '.stylua.toml',
--         'stylua.toml',
--         'selene.toml',
--         'selene.yml',
--         '.git',
--     },
--     settings = {
--         Lua = {
--             runtime = {
--                 version = "Lua 5.4",
--             },
--             completion = {
--                 enable = true,
--             },
--             diagnostics = {
--                 enable = true,
--                 globals = { "vim" },
--             },
--             workspace = {
--                 library = { vim.env.VIMRUNTIME },
--                 checkThirdParty = false,
--             },
--         },
--     },
-- }

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


-- ~/.config/nvim-new/lua/keymaps.lua
-- keymap("n", "<leader>ff", '<cmd>FzfLua files<CR>')
-- keymap("n", "<leader>fg", '<cmd>FzfLua live_grep<CR>')

-- ~/.config/nvim-new/lua/plugins.lua
-- vim.pack.add({
--     { src = "https://github.com/tpope/vim-fugitive" },
-- })

-- ~/.config/nvim-new/lua/keymaps.lua
-- keymap("n", "<leader>gs", '<cmd>Git<CR>', opts)
-- keymap("n", "<leader>gp", '<cmd>Git push<CR>', opts)
