-- ftplugin/python.lua  ─  runs once per Python buffer
-- Starts pyright + ruff, wires Python-specific keymaps and DAP
vim.bo.shiftwidth  = 4
vim.bo.tabstop     = 4
vim.bo.softtabstop = 4

local api  = vim.api
local P    = require("util.platform")

-- ── Root dir ──────────────────────────────────────────────────────────────────
local root_dir = vim.fs.root(0, {
  "pyproject.toml","setup.py","setup.cfg","requirements.txt",
  "Pipfile","poetry.lock",".git",
}) or assert(vim.uv.cwd(), "Could not determine working directory")

-- ── Start pyright ─────────────────────────────────────────────────────────────
local ok, me_lsp = pcall(require, "me.lsp")
local caps = ok and me_lsp.mk_config().capabilities
  or vim.lsp.protocol.make_client_capabilities()


-- Auto-detect virtualenv
local venv_dirs = { "venv",".venv","env",".env" }
local cmd_env   = {}
for _, vd in ipairs(venv_dirs) do
  local p = root_dir .. "/" .. vd
  if vim.uv.fs_stat(p) then
    cmd_env["VIRTUAL_ENV"]  = p
    cmd_env["PYTHONPATH"]   = root_dir
    break
  end
end

vim.lsp.start({
  name         = "pyright",
  cmd          = { "pyright-langserver","--stdio" },
  root_dir     = root_dir,
  capabilities = caps,
  cmd_env      = cmd_env,
  settings     = {
    python = {
      analysis = {
        autoSearchPaths        = true,
        diagnosticMode         = "workspace",
        useLibraryCodeForTypes = true,
        typeCheckingMode       = "standard",
        inlayHints             = {
          variableTypes       = true,
          functionReturnTypes = true,
          callArgumentNames   = true,
          pytestParameters    = true,
        },
      },
      pythonPath = cmd_env["VIRTUAL_ENV"] and (
            cmd_env["VIRTUAL_ENV"] .. (P.is_win and "/Scripts/python.exe" or "/bin/python")
          ) or nil,
    },
  },
}, {
  bufnr = api.nvim_get_current_buf(),
  reuse_client = function(client, cfg)
    return client.name == cfg.name and client.config.root_dir == cfg.root_dir
  end,
})

-- ============================================================================
--  Python
--  Install: pip install debugpy
-- ============================================================================
local ok, dap = pcall(require, "dap"); if not ok then return end
local ok_dap_py, dap_py = pcall(require, "dap-python")
if ok_dap_py then
  local python_exe = vim.fn.exepath("python")
  if python_exe == "" then
    python_exe = vim.fn.exepath("py")
  end
  if python_exe == "" then
    python_exe = vim.fn.exepath("python3")
  end

  if python_exe ~= "" then
    dap_py.setup(python_exe)
    dap_py.test_runner = "pytest"

    dap.configurations.python = {
      {
        type = "python",
        request = "launch",
        name = "Python current file",
        program = "${file}",
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        justMyCode = true,
      },
      {
        type = "python",
        request = "launch",
        name = "Python pytest current file",
        module = "pytest",
        args = { "${file}", "-v" },
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        justMyCode = false,
      },
      {
        type = "python",
        request = "launch",
        name = "Python module",
        module = function ()
          local value = vim.fn.input("Python module: ")
          return value ~= "" and value or nil
        end,
        cwd = "${workspaceFolder}",
        console = "integratedTerminal",
        justMyCode = true,
      },
      {
        type = "python",
        request = "launch",
        name = "Python Flask",
        module = "flask",
        cwd = "${workspaceFolder}",
        env = {
          FLASK_APP = "${workspaceFolder}/app.py",
          FLASK_DEBUG = "1",
        },
        args = { "run", "--no-debugger", "--no-reload" },
        jinja = true,
        justMyCode = true,
      },
      {
        type = "python",
        request = "launch",
        name = "Python Django",
        program = "${workspaceFolder}/manage.py",
        cwd = "${workspaceFolder}",
        args = { "runserver", "--noreload" },
        django = true,
        justMyCode = true,
      },
      {
        type = "python",
        request = "attach",
        name = "Python attach :5678",
        connect = {
          host = "127.0.0.1",
          port = 5678,
        },
      },
      {
        type = "python",
        request = "attach",
        name = "Python: attach (custom)",
        connect = function()
          local host = vim.fn.input("Host [127.0.0.1]: ", "127.0.0.1")
          local port = tonumber(vim.fn.input("Port [5678]: ", "5678")) or 5678
          return {
            host = host ~= "" and host or "127.0.0.1",
            port = port,
          }
        end,
      },
    }
  else
    vim.notify("Python executable not found in PATH", vim.log.levels.ERROR)
  end

  vim.keymap.set("n", "<leader>dpm", function()
    dap_py.test_method()
  end, { desc = "DAP Python test method" })
  vim.keymap.set("n", "<leader>dpc", function()
    dap_py.test_class()
  end, { desc = "DAP Python test class" })
  vim.keymap.set("v", "<leader>dps", function()
    dap_py.debug_selection()
  end, { desc = "DAP Python debug selection" })
end

-- ── Alternate file: test ↔ implementation ────────────────────────────────────
local bufnr = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_create_user_command(bufnr, "A", function()
  local cur  = api.nvim_buf_get_name(0)
  local base = vim.fn.fnamemodify(cur, ":t:r")
  local dir  = vim.fn.fnamemodify(cur, ":h")
  local alt
  if base:match("^test_") then
    alt = dir:gsub("/tests$","") .. "/" .. base:gsub("^test_","") .. ".py"
    if not vim.uv.fs_stat(alt) then
      alt = dir:gsub("/tests/?$","") .. "/src/" .. base:gsub("^test_","") .. ".py"
    end
  else
    alt = dir .. "/tests/test_" .. base .. ".py"
    if not vim.uv.fs_stat(alt) then
      alt = dir:gsub("/src/?$","") .. "/tests/test_" .. base .. ".py"
    end
  end
  if vim.uv.fs_stat(alt) then vim.cmd.edit(alt)
  else vim.notify("Alternate not found: "..alt, vim.log.levels.WARN) end
end,{ desc = "goto alternate (test ↔ impl)" })





