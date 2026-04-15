-- ============================================================================
-- lua/me/lsp.lua
-- MasonInstall: basedpyright, clangd, codelldb, debugpy, java-debug-adapter
--               java-test, jdtls, js-debug-adapter, lua-language-server
--               pyright, ruff, typescript-language-server
-- ============================================================================
local ok_ms, ms =  pcall(require, "mason")
-- Initialize Mason
if ok_ms then
  ms.setup({})
end
-- Define exactly what you want installed
local ensure_installed = {
    -- Language Servers
    "lua-language-server",
	"basedpyright",
	"clangd",
	"codelldb",
    "typescript-language-server",
    "pyright",
    "jdtls",

    -- Debug Adapters
    "debugpy",
    "js-debug-adapter",
	"java-debug-adapter",
	"java-test",
}

-- Write the auto-install script
local mason_registry = require("mason-registry")

-- Refresh the registry in the background
mason_registry.refresh(function()
    for _, tool in ipairs(ensure_installed) do
        -- Check if the tool exists in Mason's registry safely
        local ok, pkg = pcall(mason_registry.get_package, tool)

        if ok and not pkg:is_installed() then
            -- Schedule the installation so it doesn't block the UI
            vim.schedule(function()
                vim.notify("Mason is auto-installing: " .. tool, vim.log.levels.INFO)
                pkg:install()
            end)
        end
    end
end)

vim.diagnostic.config({
	virtual_text = {
        prefix = "●",
        spacing = 4,
        severity = { min = vim.diagnostic.severity.WARN },
    },
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = " ",
			[vim.diagnostic.severity.WARN]  = " ",
			[vim.diagnostic.severity.INFO]  = "",
			[vim.diagnostic.severity.HINT]  = "",
		},
        numhl = {
            [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
            [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
        }
	},
	underline = { severity = { min = vim.diagnostic.severity.WARN } },
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
		header = "",
		prefix = "",
		focusable = true,
		-- style = "minimal",
        format  = function(d)
            local src = d.source and ("[" .. d.source .. "] ") or ""
            local code = d.code  and ("[" .. d.code .. "] ") or ""
            return src .. d.message .. code
        end,
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

-- ── Modernize the popup menu behavior ───────────────────────────────────────────────────────────────────
-- Enable Native Completion Options
vim.opt.autocomplete = true             -- Enable native auto-triggering as you type
vim.opt.autocompletetimeout = 200       -- Cap the lookup time so the editor doesn't freeze (defaults to 200ms)

-- Modernize the popup menu behavior
vim.opt.completeopt = {
    "fuzzy",     -- Use native fuzzy matching (new in recent versions)
    "menuone",   -- Show the menu even if there is only one match
    "noselect",  -- Don't auto-select the first item
    "popup"      -- Use the modern floating popup UI instead of standard inline
}

-- Map Keys for the Popup Menu (PUM)
local map = vim.keymap.set

-- Confirm the completion with <Enter>
map("i", "<CR>", function()
    if vim.fn.pumvisible() == 1 then
        return "<C-y>" -- Accept the currently selected item
    end
    return "<CR>"
end, { expr = true, desc = "Confirm completion" })

-- Navigate down with <Tab>, and jump forward in snippets
map({ "i", "s" }, "<Tab>", function()
    if vim.fn.pumvisible() == 1 then
        return "<C-j>" -- Go to next item in the menu
    elseif vim.snippet.active({ direction = 1 }) then
        return "<cmd>lua vim.snippet.jump(1)<CR>" -- Jump to next snippet placeholder
    end
    return "<Tab>"
end, { expr = true, desc = "Next completion or snippet jump" })

-- Navigate up with <Shift-Tab>, and jump backward in snippets
map({ "i", "s" }, "<S-Tab>", function()
    if vim.fn.pumvisible() == 1 then
        return "<C-k>" -- Go to previous item in the menu
    elseif vim.snippet.active({ direction = -1 }) then
        return "<cmd>lua vim.snippet.jump(-1)<CR>" -- Jump to previous snippet placeholder
    end
    return "<S-Tab>"
end, { expr = true, desc = "Previous completion or snippet jump" })

vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local bufnr = args.buf
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if not client then
          return
        end
        -- Enable native Neovim 0.12 completion if the server supports it
        if client and client.server_capabilities.completionProvider then
            vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
        end

        local _map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end

        _map('n', 'K', vim.lsp.buf.hover, 'LSP Hover')
        _map('n', 'gd', vim.lsp.buf.definition, 'Go to definition')
        _map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
        _map('n', 'gi', vim.lsp.buf.implementation, 'Go to implementation')
        _map('n', 'gr', vim.lsp.buf.references, 'References')

        _map('n', '<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
        _map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, 'Code action')

        _map('n', '<leader>f', function()
            vim.lsp.buf.format({ async = true })
        end, 'Format buffer')
        _map("n", "<leader>gS", function()
            vim.cmd("vsplit")
            vim.lsp.buf.definition()
        end, "Go to definition with splited window")

        -- _map("n", "<leader>D", function()
        --   vim.diagnostic.open_float({ scope = "line" })
        -- end, "Diagnostic Open float window")
        -- _map("n", "<leader>d", function()
        --   vim.diagnostic.open_float({ scope = "cursor" })
        -- end, "Diagnostic Open float window")
        -- _map("n", "<leader>nd", function()
        --   vim.diagnostic.jump({ count = 1 })
        -- end, "Diagnostic jump")
        -- _map("n", "<leader>pd", function()
        --   vim.diagnostic.jump({ count = -1 })
        -- end, "Diagnostic jump")

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
          end, { noremap = true, silent = true, buffer = bufnr })
        end

    end,
})

vim.lsp.enable({
	"lua_ls",
	"pyright",
	"ts_ls",
    "jsonls"
})
