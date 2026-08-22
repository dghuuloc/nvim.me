-- ============================================================================
-- lua/me/lsp.lua
-- MasonInstall: basedpyright, clangd, codelldb, debugpy, java-debug-adapter
--               java-test, jdtls, js-debug-adapter, lua-language-server
--               pyright, ruff, typescript-language-server
-- ============================================================================
local M = {}

local ok_ms, ms = pcall(require, "mason")
-- Initialize Mason
if ok_ms then
  ms.setup({})
end
-- Define exactly what you want installed
local ensure_installed = {
  -- Language Servers
  "lua-language-server",
  "clangd",
  "json-lsp",
  "typescript-language-server",
  -- "pyright",
  "basedpyright",
  "ruff",
  "jdtls",

  -- Debug Adapters
  "codelldb",
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


-- ── Capability builder ───────────────────────────────────────────────────────
function M.mk_config(extra)
  -- Request snippet support, folding, watched files
  local caps = vim.tbl_deep_extend("force",
    vim.lsp.protocol.make_client_capabilities(),
    {
      workspace    = { didChangeWatchedFiles = { dynamicRegistration = true } },
      textDocument = {
        completion = {
          completionItem = {
            snippetSupport = true,
            resolveSupport = { properties = { "documentation", "detail", "additionalTextEdits" } },
          }
        },
        foldingRange = { dynamicRegistration = false, lineFoldingOnly = true },
      },
    })
  return vim.tbl_deep_extend("force",
    { handlers = {}, capabilities = caps, init_options = vim.empty_dict(), settings = vim.empty_dict() },
    extra or {})
end

-- ── Diagnostic configuration ─────────────────────────────────────────────────
vim.diagnostic.config({
  -- virtual_text     = {
  --   prefix = "●",
  --   spacing = 4,
  --   severity = { min = vim.diagnostic.severity.WARN },
  -- },
  virtual_text = false,

  -- 0.12: virtual_lines — shows diagnostics as full lines below code.
  -- Toggle with <leader>xL. Off by default to avoid clutter.
  virtual_lines    = false,

  -- signs            = {
  --   text = {
  --     [vim.diagnostic.severity.ERROR] = " ",
  --     [vim.diagnostic.severity.WARN]  = " ",
  --     [vim.diagnostic.severity.INFO]  = "",
  --     [vim.diagnostic.severity.HINT]  = "",
  --   },
  --   numhl = {
  --     [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
  --     [vim.diagnostic.severity.WARN] = "DiagnosticSignWarn",
  --   }
  -- },
  signs = false,

  -- underline        = { severity = { min = vim.diagnostic.severity.WARN } },
  underline = false,

  update_in_insert = false,
  severity_sort    = true,
  float            = {
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
    focusable = true,
    format = function(d)
      local src = d.source and ("[" .. d.source .. "] ") or ""
      local code = d.code and ("[" .. d.code .. "] ") or ""
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
  "menuone",  -- Show the menu even if there is only one match
  "noselect", -- Don't auto-select the first item
  "popup"     -- Use the modern floating popup UI instead of standard inline
}

-- ── LspAttach ─────────────────────────────────────────────────────────────────
vim.api.nvim_create_autocmd('LspAttach', {
  group    = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    -- ── Ruff / Pyright responsibility separation ───────────────────────
    if client.name == "ruff" then
      client.server_capabilities.hoverProvider = false
    end

    -- ── Native autotrigger completion ──────────────────────────────────
    if client.server_capabilities.completionProvider then
      -- Extend trigger characters to include vowels (jdtls + pyright benefit)
      local t = vim.tbl_get(
        client.server_capabilities, "completionProvider", "triggerCharacters"
      ) or {}
      for _, ch in ipairs({ "a", "e", "i", "o", "u" }) do
        if not vim.tbl_contains(t, ch) then table.insert(t, ch) end
      end

      -- Write the updated table back do jdtls picks up the new trigger
      client.server_capabilities.completionProvider.triggerCharacters = t

      -- This is the key 0.12 API: starts native completion for this buffer
      vim.lsp.completion.enable(true, client.id, bufnr, {
        autotrigger = true, -- trigger automatically while typing
      })
    end

    -- ── Buffer-local nav keymaps ───────────────────────────────────────
    local _map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    _map("n", "K", vim.lsp.buf.hover, "LSP: hover docs")
    _map("n", "gd", vim.lsp.buf.definition, "LSP: go to definition")
    _map("n", "gD", vim.lsp.buf.declaration, "LSP: go to declaration")
    _map("n", "gi", vim.lsp.buf.implementation, "LSP: go to implementation")
    _map("n", "gr", vim.lsp.buf.references, "LSP: references")
    _map("n", "gy", vim.lsp.buf.type_definition, "LSP: type definition")

    _map("n", "<leader>rn", function()
      local old = vim.fn.expand("<cword>")
      vim.ui.input({ prompt = "Rename: ", default = old }, function(new)
        if new and new ~= "" and new ~= old then vim.lsp.buf.rename(new) end
      end)
    end, "LSP: rename symbol")

    _map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: code action")
    _map({ "n", "v" }, "<a-CR>", vim.lsp.buf.code_action, "LSP: code action")

    _map("n", "<leader>f", function()
      local filetype = vim.bo[bufnr].filetype

      -- Python -> always use Ruff
      if filetype == "python" then
        vim.lsp.buf.format({
          bufnr = bufnr,
          name = "ruff",
          async = false,
          timeout_ms = 3000,
        })
        return
      end

      -- TypeScript
      local ts_filetypes = {
        javascript = true,
        javascriptreact = true,
        typescript = true,
        typescriptreact = true,
      }

      if ts_filetypes[filetype] then
        vim.lsp.buf.format({
          bufnr = bufnr,
          name = "ts_ls",
          async = false,
          timeout_ms = 3000,
        })

        return
      end

      -- Other languages -> use their normal LSP formatter
      vim.lsp.buf.format({
        bufnr = bufnr,
        async = true,
        timeout_ms = 3000,
      })

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
vim.lsp.config["*"] = M.mk_config()

-- ── Ruff ─────────────────────────────────────────────────────────────────────
vim.lsp.config("ruff", {
  cmd = {
    "ruff",
    "server",
  },

  filetypes = {
    "python",
  },

  root_markers = {
    "pyproject.toml",
    "ruff.toml",
    ".ruff.toml",
    ".git",
  },

  init_options = {
    settings = {
      -- Enable Ruff lint diagnostics.
      lint = {
        enable = true,

        select = { "E", "W", "F", "I" },
      },

      -- PEP 8 formatter/linter line length.
      lineLength = 79,

      -- Ruff configuration supplied directly by Neovim.
      configuration = {
        ["indent-width"] = 4,

        lint = {
          -- Rules that can conflict with Ruff formatter.
          ignore = { "E111", "E114", "E117", "W191" },

          pycodestyle = {
            -- PEP 8 code lines.
            ["max-line-length"] = 79,

            -- PEP 8 comments/docstrings.
            ["max-doc-length"] = 72,
          },
        },

        format = {
          ["indent-style"] = "space",
          ["quote-style"] = "double",
          ["line-ending"] = "auto",

          ["skip-magic-trailing-comma"] = false,

          ["docstring-code-format"] = true,
          ["docstring-code-line-length"] = "dynamic",
        },
      },

      -- Keep Pyright responsible for Python intelligence.
      fixAll = false,
      organizeImports = true,
    },
  },
})

vim.lsp.enable({
  "lua_ls",
  "ts_ls",
  "jsonls",
  "basedpyright",
  "ruff",
  "clangd",
})

-- ── Completion keymaps ────────────────────────────────────────────────────────
-- <C-Space>: manually trigger completion
vim.keymap.set("i", "<C-Space>", function()
  if vim.fn.pumvisible() == 1 then
    return vim.api.nvim_replace_termcodes("<C-e>", true, false, true)
  else
    vim.lsp.completion.get()
  end
end, { silent = true, desc = "trigger / close completion" })

-- <C-l>: accept selected item OR trigger completion
vim.keymap.set("i", "<C-l>", function()
  local info = vim.fn.complete_info({ "pum_visible", "selected" })
  if info.pum_visible == 1 then
    if info.selected == -1 then
      vim.api.nvim_feedkeys(vim.keycode("<C-n>"), "n", true)
    end
    vim.api.nvim_feedkeys(vim.keycode("<C-y>"), "n", true)
  elseif next(vim.lsp.get_clients({ bufnr = 0 })) then
    vim.lsp.completion.get()
  else
    vim.api.nvim_feedkeys(vim.keycode("<C-x><C-n>"), "n", true)
  end
end, { silent = true, desc = "accept/trigger completion" })

-- <CR>: accept if item selected, else newline
vim.keymap.set("i", "<CR>", function()
  return vim.fn.pumvisible() == 1 and vim.keycode("<C-y>") or vim.keycode("<CR>")
end, { expr = true, silent = true })

-- <C-j>/<C-k>: navigate menu
vim.keymap.set("i", "<C-j>", function()
  return vim.fn.pumvisible() == 1 and vim.keycode("<C-n>") or vim.keycode("<C-j>")
end, { expr = true, silent = true, desc = "completion: next item" })
vim.keymap.set("i", "<C-k>", function()
  return vim.fn.pumvisible() == 1 and vim.keycode("<C-p>") or vim.keycode("<C-k>")
end, { expr = true, silent = true, desc = "completion: prev item" })

-- <C-e>: cancel completion
vim.keymap.set("i", "<C-e>", function()
  return vim.fn.pumvisible() == 1 and vim.keycode("<C-e>") or vim.keycode("<C-e>")
end, { expr = true, silent = true, desc = "cancel completion" })

-- <Tab>/<S-Tab>: snippet navigation (native vim.snippet) with pum fallback
vim.keymap.set({ "i", "s" }, "<Tab>", function()
  if vim.snippet.active({ direction = 1 }) then
    vim.snippet.jump(1); return ""
  end
  if vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-n>")
  end
  return vim.keycode("<Tab>")
end, { expr = true, silent = true, desc = "snippet next / menu next / tab" })

vim.keymap.set({ "i", "s" }, "<S-Tab>", function()
  if vim.snippet.active({ direction = -1 }) then
    vim.snippet.jump(-1); return ""
  end
  if vim.fn.pumvisible() == 1 then
    return vim.keycode("<C-p>")
  end
  return vim.keycode("<S-Tab>")
end, { expr = true, silent = true, desc = "snippet prev / menu prev / S-tab" })

-- <Esc>: exit snippet mode if active, else normal Esc
vim.keymap.set({ "i", "s" }, "<Esc>", function()
  if vim.snippet.active() then vim.snippet.stop() end
  return vim.keycode("<Esc>")
end, { expr = true, silent = true })

return M
