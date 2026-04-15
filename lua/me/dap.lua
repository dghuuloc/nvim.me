-- ============================================================================
-- lua/me/dap.lua
-- Windows-first DAP setup for Neovim 0.12 + native vim.pack
-- Languages: Python, JavaScript, TypeScript, C/C++, Java (attach + jdtls integration)
-- ============================================================================

-- ── DAP ────────────────────────────────────────────────────────────────────
local ok_dap, dap = pcall(require, "dap")
if not ok_dap then
  return
end

-- ── DAP UI ─────────────────────────────────────────────────────────────────
local ok_dapui, dapui = pcall(require, "dapui")
if ok_dapui then
  dapui.setup({
    icons   = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
    layouts = {
      {
        elements = {
          { id = "scopes",      size = 0.35 },
          { id = "breakpoints", size = 0.15 },
          { id = "stacks",      size = 0.30 },
          { id = "watches",     size = 0.20 },
        },
        size = 42,
        position = "left",
      },
      {
        elements = {
          { id = "repl",    size = 0.5 },
          { id = "console", size = 0.5 },
        },
        size = 12,
        position = "bottom",
      },
    },
    controls = {
      enabled = true,
      element = "repl",       -- attach toolbar to repl panel
    },
    floating = {
      border = "rounded"
    },
    -- Force the console to show output immediately
    render = {
      indent     = 1,
      max_value_lines = 100,
    },
  })

  -- Automatically open the UI when a new debug session is created
  dap.listeners.after.event_initialized["dapui_config"] = function()
    dapui.open()
  end
  -- Automatically close the UI when a new debug session is created
  dap.listeners.before.event_terminated["dapui_config"] = function()
    dapui.close("tray")
  end
  dap.listeners.before.event_exited["dapui_config"] = function()
    dapui.close("tray")
  end
end

local function dapui_close_all()
  if not ok_dapui then
    return
  end
  pcall(dapui.close, "tray")
  pcall(dapui.close, "sidebar")
end

-- ── Virtual text for variable values ─────────────────────────────────────────
local ok_vt, vt = pcall(require, "nvim-dap-virtual-text")
if ok_vt then
  vt.setup({
    enabled                     = true,
    commented                   = false,
    highlight_changed_variables = true,
    highlight_new_as_changed    = true,
    show_stop_reason            = true,
    virt_text_pos               = "eol",
  })
end

-- ── Breakpoint signs ─────────────────────────────────────────────────────────
vim.fn.sign_define("DapBreakpoint",          { text = "●", texthl = "DiagnosticError", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn",  linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected",  { text = "○", texthl = "DiagnosticError", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped",             { text = "▶", texthl = "DiagnosticOk",    linehl = "DapStoppedLine", numhl = "" })
vim.fn.sign_define("DapLogPoint",            { text = "◎", texthl = "DiagnosticInfo",  linehl = "", numhl = "" })

-- ============================================================================
--  Arrow keys remap during debug session
-- ============================================================================
-- set a vim motion to start the debugger and launch the debugging ui
-- (Resume execution): This allows you to continue executing the program without stopping debugging.
vim.keymap.set("n", "<F5>",  dap.continue,  { desc = "DAP start/continue" })
-- (Step over): This assists in moving to the next line without leaving debug mode.
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "DAP step over" })
-- (Step into): This allows you to enter debug mode.
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "DAP step into" })
-- (Step out): This allows you to step out/return to the current method/caller in debug mode.
vim.keymap.set("n", "<F12>", dap.step_out,  { desc = "DAP step out" })

-- Setup debug toggle_breakpoint
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "DAP conditional breakpoint" })

vim.keymap.set("n", "<leader>dc", dap.run_to_cursor, { desc = "DAP run to cursor" })
vim.keymap.set("n", "<leader>dr", dap.repl.toggle,   { desc = "DAP REPL" })
vim.keymap.set("n", "<leader>du", function()
  if ok_dapui then
    dapui.toggle({})
  end
end, { desc = "DAP UI toggle" })
vim.keymap.set("n", "<leader>dx", dap.terminate, { desc = "DAP terminate" })
-- set a vim motion to close the debugging ui
vim.keymap.set("n", "<leader>dC", dapui_close_all, { desc = "Debug Close UI" })
-- set a vim motions to close debugger and clear breakpoints
vim.keymap.set("n", "<leader>de", function()
  dap.clear_breakpoints()
  -- dapui.toggle({})
  dapui_close_all()
  dap.terminate()
  vim.api.nvim_feedkeys ( vim.api.nvim_replace_termcodes("<C-w>=", false, true, true), "n", false)
end, { desc = "Close debugger and end debugging session" })

-- set a vim motions to evaluate expression
vim.keymap.set({ "n", "v" }, "<F2>", function()
  if ok_dapui then
    dapui.eval()
  end
end, { desc = "DAP Evaluate" })
-- set a vim motions to evaluate input expression
vim.keymap.set("n", "<F3>", function()
  if ok_dapui then
    dapui.eval(vim.fn.input("Expression > "))
  end
end, { desc = "DAP Evaluate Input" })
-- set a vim motions to hover Variables
vim.keymap.set("n", "<F4>", function()
  require("dap.ui.widgets").hover()
end, { desc = "DAP Hover Variables" })
vim.keymap.set("n", "<leader>dL", function()
  dap.set_log_level("TRACE")
  vim.cmd("DapShowLog")
end, { desc = "DAP show log" })

-- ============================================================================
--  Python
--  Install: pip install debugpy
-- ============================================================================
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
end

vim.keymap.set("n", "<leader>dpm", function()
  require("dap-python").test_method()
end, { desc = "DAP Python test method" })

vim.keymap.set("n", "<leader>dpc", function()
  require("dap-python").test_class()
end, { desc = "DAP Python test class" })

vim.keymap.set("v", "<leader>dps", function()
  require("dap-python").debug_selection()
end, { desc = "DAP Python debug selection" })

-- ============================================================================
--  JavaScript / TypeScript
--  Install: npm install -g @vscode/debugadapter
--  OR: MasonInstall js-debug-adapter
-- ============================================================================
local mason_js_debug = vim.fn.stdpath("data") ..
  "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"

if vim.uv.fs_stat(mason_js_debug) then
  dap.adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "node",
      args    = { mason_js_debug, "${port}", "localhost" },
    },
  }
  dap.adapters["pwa-chrome"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
      command = "node",
      args    = { mason_js_debug, "${port}", "localhost" },
    },
  }

  local js_configs = {
    {
      name      = "Launch current file",
      type      = "pwa-node",
      request   = "launch",
      program   = "${file}",
      cwd       = "${workspaceFolder}",
      sourceMaps = true,
      console = "integratedTerminal",
      skipFiles = { "<node_internals>/**" },
    },
    {
      name      = "Launch npm start",
      type      = "pwa-node",
      request   = "launch",
      runtimeExecutable = "npm",
      runtimeArgs       = { "start" },
      cwd       = "${workspaceFolder}",
      sourceMaps = true,
    },
    {
      name    = "Attach Node process",
      type    = "pwa-node",
      request = "attach",
      processId = require("dap.utils").pick_process,
      cwd     = "${workspaceFolder}",
      sourceMaps = true,
    },
    {
      name    = "Debug Jest tests",
      type    = "pwa-node",
      request = "launch",
      runtimeExecutable = "node",
      runtimeArgs       = {
        "./node_modules/jest/bin/jest.js",
        "--runInBand",
      },
      cwd         = "${workspaceFolder}",
      rootPath    = "${workspaceFolder}",
      sourceMaps  = true,
      console     = "integratedTerminal",
      internalConsoleOptions = "neverOpen",
    },
    {
      type = "pwa-node",
      request = "launch",
      name = "TypeScript current file (tsx)",
      program = "${file}",
      cwd = "${workspaceFolder}",
      runtimeExecutable = "tsx",
      sourceMaps = true,
      console = "integratedTerminal",
      skipFiles = { "<node_internals>/**" },
    },
    {
      name    = "Chrome localhost:3000",
      type    = "pwa-chrome",
      request = "launch",
      url = function()
        local value = vim.fn.input("URL [http://localhost:3000]: ", "http://localhost:3000")
        return value ~= "" and value or "http://localhost:3000"
      end,
      webRoot = "${workspaceFolder}",
      sourceMaps = true,
    },
    {
      type = "pwa-msedge",
      request = "launch",
      name = "Edge: localhost:3000",
      url = function()
          local value = vim.fn.input("URL [http://localhost:3000]: ", "http://localhost:3000")
          return value ~= "" and value or "http://localhost:3000"
      end,
      webRoot = "${workspaceFolder}",
      sourceMaps = true,
    },
  }

  for _, ft in ipairs({ "javascript","typescript","javascriptreact","typescriptreact" }) do
    dap.configurations[ft] = js_configs
  end
end

-- ============================================================================
-- C / C++
-- Windows + CodeLLDB
-- Install first: :MasonInstall codelldb
-- ============================================================================
local mason_pkg = vim.fn.stdpath("data") .. "/mason/packages/codelldb"
-- Windows paths use backslash internally but Neovim accepts forward slash
local codelldb_exe = mason_pkg .. "/extension/adapter/codelldb.exe"
local liblldb_dll  = mason_pkg .. "/extension/lldb/bin/liblldb.dll"

if vim.fn.filereadable(codelldb_exe) == 1 then
  dap.adapters.codelldb = {
    type = "server",
    port = "${port}",
    executable = {
      command = codelldb_exe,
      args = {
        "--port", "${port}",
        "--liblldb", liblldb_dll,
      },
      detached = false, -- important on Windows
    },
  }
  dap.configurations.cpp = {
    {
      name = "Launch",
      type = "codelldb",
      request = "launch",
      program = function()
        return vim.fn.input({
          prompt      = "Path to .exe: ",
          default     = vim.fn.getcwd() .. "\\",
          completion  = "file",
        })
      end,
      cwd         = "${workspaceFolder}",
      stopOnEntry = false,
      args        = function()
        local input = vim.fn.input("Arguments: ")
        return input == "" and {} or vim.split(input, "%s+")
      end,
    },
    {
      name = "Attach to process",
      type = "codelldb",
      request = "attach",
      pid = require("dap.utils").pick_process,
      cwd = "${workspaceFolder}",
    },
  }
  dap.configurations.c = dap.configurations.cpp
end

-- ============================================================================
--  Java
--  Handled by nvim-jdtls (see ftplugin/java.lua)
--  java-debug jar is injected as a jdtls bundle there.
-- ============================================================================
dap.configurations.java = {
  {
    name     = "Java Attach (5005)",
    type     = "java",
    request  = "attach",
    hostName = "localhost",
    port     = 5005,
  },
  {
    name     = "Java Attach (custom port)",
    type     = "java",
    request  = "attach",
    hostName = "localhost",
    port     = function()
      return tonumber(vim.fn.input({ prompt = "Debug port: ", default = "5005" })) or 5005
    end,
  },
  {
    name     = "Spring Boot attach",
    type     = "java",
    request  = "attach",
    hostName = "localhost",
    port     = 5005,
  },
  {
    name    = "Java Remote Docker",
    type    = "java",
    request = "attach",
    hostName = function() return vim.fn.input({ prompt = "Host: ", default = "localhost" }) end,
    port     = function()
      return tonumber(vim.fn.input({ prompt = "Port: ", default = "5005" })) or 5005
    end,
  },
}
