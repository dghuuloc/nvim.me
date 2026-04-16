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

-- ── FIX 1: Capabilities — MUST be set before vim.lsp.enable() ────────────────
-- This is the root cause of missing Java built-in completions.
-- jdtls only returns String/List/Map/int/... completions when the client
-- declares snippetSupport=true and resolveSupport.
-- lsp.config["*"] applies these capabilities to EVERY server automatically.
vim.lsp.config["*"] = {
  capabilities = vim.tbl_deep_extend("force",
    vim.lsp.protocol.make_client_capabilities(),
    {
      workspace = {
        didChangeWatchedFiles = { dynamicRegistration = true },
      },
      textDocument = {
        completion = {
          completionItem = {
            snippetSupport  = true,   -- required for jdtls to return full items
            resolveSupport  = {
              properties = { "documentation", "detail", "additionalTextEdits" },
            },
            documentationFormat = { "markdown", "plaintext" },
            deprecatedSupport   = true,
            preselectSupport    = true,
          },
        },
        -- Needed for jdtls to register folding providers
        foldingRange = { dynamicRegistration = false, lineFoldingOnly = true },
      },
    }),
}

-- ── Diagnostic configuration ─────────────────────────────────────────────────
vim.diagnostic.config({
	virtual_text = {
        prefix = "●",
        spacing = 4,
        severity = { min = vim.diagnostic.severity.WARN },
  },

  -- 0.12: virtual_lines — shows diagnostics as full lines below code.
  -- Toggle with <leader>xL. Off by default to avoid clutter.
  virtual_lines = false,

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
	underline        = { severity = { min = vim.diagnostic.severity.WARN } },
	update_in_insert = false,
	severity_sort    = true,
	float = {
		border = "rounded", source = true, header = "", prefix = "", focusable = true,
    format  = function(d)
        local src = d.source and ("[" .. d.source .. "] ") or ""
        local code = d.code  and ("[" .. d.code .. "] ") or ""
        return src .. d.message .. code
    end,
	},
})

do
	local orig = vim.lsp.util.open_floating_preview
  ---@diagnostic disable-next-line: duplicate-set-field
	function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
		opts = opts or {}
		opts.border = opts.border or "rounded"
		return orig(contents, syntax, opts, ...)
	end
end

-- ── Modernize the popup menu behavior ───────────────────────────────────────────────────────────────────
-- Enable Native Completion Options
-- vim.opt.autocomplete = true             -- Enable native auto-triggering as you type
-- vim.opt.autocompletetimeout = 200       -- Cap the lookup time so the editor doesn't freeze (defaults to 200ms)

-- Modernize the popup menu behavior
-- Native completion popup options (0.12)
-- "popup"   → floating documentation window alongside the menu (new in 0.12)
-- "fuzzy"   → fuzzy matching of items
-- "menuone" → show menu even for single result
-- "noselect"→ don't auto-select the first item
vim.opt.completeopt = {
    "fuzzy",     -- Use native fuzzy matching (new in recent versions)
    "menuone",   -- Show the menu even if there is only one match
    "noselect",  -- Don't auto-select the first item
    "popup"      -- Use the modern floating popup UI instead of standard inline
}

-- ── LspAttach ─────────────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd('LspAttach', {
  group    = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    -- ── Native autotrigger completion ──────────────────────────────────
    if client.server_capabilities.completionProvider then
      -- Extend trigger characters to include vowels (jdtls + pyright benefit)
      local t = vim.tbl_get(
        client.server_capabilities,"completionProvider","triggerCharacters"
      ) or {}
      for _, ch in ipairs({ "a","e","i","o","u" }) do
        if not vim.tbl_contains(t, ch) then table.insert(t, ch) end
      end

      -- Write the updated table back do jdtls picks up the new trigger
      client.server_capabilities.completionProvider.triggerCharacters = t

      -- This is the key 0.12 API: starts native completion for this buffer
      vim.lsp.completion.enable(true, client.id, bufnr, {
        autotrigger = true,   -- trigger automatically while typing
      })
    end

    -- ── navic breadcrumbs ──────────────────────────────────────────────
    -- local ok_nav,navic=pcall(require,"nvim-navic")
    -- if ok_nav and client.server_capabilities.documentSymbolProvider then
    --   navic.attach(client,bufnr) end

    -- ── Buffer-local nav keymaps ───────────────────────────────────────
    local _map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    _map("n", "K",          vim.lsp.buf.hover,          "LSP: hover docs")
    _map("n", "gd",         vim.lsp.buf.definition,     "LSP: go to definition")
    _map("n", "gD",         vim.lsp.buf.declaration,    "LSP: go to declaration")
    _map("n", "gi",         vim.lsp.buf.implementation, "LSP: go to implementation")
    _map("n", "gr",         vim.lsp.buf.references,     "LSP: references")
    _map("n", "gy",         vim.lsp.buf.type_definition,"LSP: type definition")

    _map("n", "<leader>rn", function()
      local old = vim.fn.expand("<cword>")
      vim.ui.input({ prompt = "Rename: ", default = old }, function(new)
        if new and new ~= "" and new ~= old then vim.lsp.buf.rename(new) end
      end)
    end, "LSP: rename symbol")

    _map({ "n","v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
    _map({ "n","v" }, "<a-CR>",     vim.lsp.buf.code_action, "LSP: code action")

    _map("n", "<leader>f", function()
      vim.lsp.buf.format({ async = true })
    end, "LSP: format buffer")

    _map("n", "<leader>gS", function()
      vim.cmd("vsplit")
      vim.lsp.buf.definition()
    end, "LSP: definition in split")

    -- Organize imports (works for jdtls + ts_ls)
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

vim.api.nvim_create_autocmd("LspDetach", {
  group    = vim.api.nvim_create_augroup("lsp_detach", { clear = true }),
  callback = function(args)
    pcall(vim.api.nvim_del_augroup_by_name,
      ("lsp_hl_%d_%d"):format(args.buf, args.data.client_id))
  end,
})

-- ── Enable servers ────────────────────────────────────────────────────────────
-- lsp/*.lua files auto-loaded by Neovim 0.11+ from config directory.
-- Capabilities from lsp.config["*"] are merged automatically.
vim.lsp.enable({
	"lua_ls",
	"pyright",
	"ts_ls",
  "jsonls",
  -- jdtls -> ftplugin/java.lua
  -- pyright/ruff -> ftplugin/python.lua
})

-- ── Completion keymaps ────────────────────────────────────────────────────────

-- <C-Space>: manually trigger completion
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    -- close if already open
    return vim.api.nvim_replace_termcodes("<C-e>", true, false, true)
  else
    vim.lsp.completion.trigger()
  end
end,{ silent = true, desc = "trigger / close completion" })

-- <C-l>: accept selected item OR trigger completion
vim.keymap.set("i", "<C-l>",function()
  local info=vim.fn.complete_info({"pum_visible", "selected"})
  if info.pum_visible == 1 then
    if info.selected == -1 then
      vim.api.nvim_feedkeys(vim.keycode("<C-n>"), "n", true) end
    vim.api.nvim_feedkeys(vim.keycode("<C-y>"), "n", true)
  elseif next(vim.lsp.get_clients({bufnr = 0 })) then
    vim.lsp.completion.trigger()
  else
    vim.api.nvim_feedkeys(vim.keycode("<C-x><C-n>"), "n", true)
  end
end,{ silent = true, desc = "accept/trigger completion" })

-- <CR>: accept if item selected, else newline
vim.keymap.set("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and vim.keycode("<C-y>") or vim.keycode("<CR>")
end,{ expr = true, silent = true })

-- <C-j>/<C-k>: navigate menu
vim.keymap.set("i", "<C-j>", function()
  return vim.fn.pumvisible() == 1 and vim.keycode("<C-n>") or vim.keycode("<C-j>")
end,{ expr = true, silent = true, desc = "completion: next item" })
vim.keymap.set("i","<C-k>", function()
  return vim.fn.pumvisible() == 1 and vim.keycode("<C-p>") or vim.keycode("<C-k>")
end,{ expr = true, silent = true, desc = "completion: prev item" })

-- <C-e>: cancel completion
vim.keymap.set("i", "<C-e>", function()
  return vim.fn.pumvisible() == 1 and vim.keycode("<C-e>") or vim.keycode("<C-e>")
end,{ expr = true, silent = true, desc = "cancel completion" })

-- <Tab>/<S-Tab>: snippet navigation (native vim.snippet) with pum fallback
vim.keymap.set({ "i", "s" }, "<Tab>", function()
  if vim.snippet.active({ direction = 1 }) then
    vim.snippet.jump(1); return ""
  end
  if vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-n>")
  end
  return vim.keycode("<Tab>")
end,{ expr = true, silent = true, desc = "snippet next / menu next / tab" })

vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
  if vim.snippet.active({direction = -1}) then
    vim.snippet.jump(-1); return ""
  end
  if vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-p>")
  end
  return vim.keycode("<S-Tab>")
end,{ expr = true, silent = true, desc = "snippet prev / menu prev / S-tab" })

-- <Esc>: exit snippet mode if active, else normal Esc
vim.keymap.set({ "i","s" }, "<Esc>", function()
  if vim.snippet.active() then vim.snippet.stop() end
  return vim.keycode("<Esc>")
end,{ expr = true, silent = true })
