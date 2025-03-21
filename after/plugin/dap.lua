local dap = require("dap")
local dapui = require("dapui")

-- Setup the dap ui with default configuration
dapui.setup({})

-- Automatically open the UI when a new debug session is created.
dap.listeners.before.launch.dapui_config = function()
    dapui.open()
end
dap.listeners.before.attach.dapui_config = function()
    dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
end

-- (Step into): This allows you to enter debug mode.
vim.keymap.set("n", "<F5>", dap.step_into, { desc = "Step Into" })
-- (Step over): This assists in moving to the next line without leaving debug mode.
vim.keymap.set("n", "<F6>", dap.step_over, { desc = "Step Over" })
-- (Step out): This allows you to step out/return to the current method/caller in debug mode.
vim.keymap.set("n", "<F7>", dap.step_out, { desc = "Step Out" })
-- (Resume execution): This allows you to continue executing the program without stopping debugging.
vim.keymap.set("n", "<F8>", dap.continue, { desc = "Debug Start" })
-- (Toggle breakpoint): This allows you to set or remove a breakpoint on the current line of code.
vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "Debug Toggle Breakpoint" })
-- set a vim motion to close the debugging ui
vim.keymap.set("n", "<leader>dc", dapui.close, { desc = "Debug Close" })
-- set a vim motions to close debugger and clear breakpoints
vim.keymap.set("n", "<leader>de", function()
    dap.clear_breakpoints()
    dapui.toggle({})
    dap.terminate()
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w>=", false, true, true), "n", false)
end, { desc = "Close debugger and end debugging session" })
-- set a vim motions to evaluate expression
vim.keymap.set({ "n", "v" }, "<F2>", function()
    dapui.eval()
end, { desc = "Evaluate" })
-- set a vim motions to evaluate input expression
vim.keymap.set("n", "<F3>", function()
    dapui.eval(vim.fn.input("Expression > "))
end, { desc = "Evaluate Input" })
-- set a vim motions to hover Variables
vim.keymap.set("n", "<F4>", function()
    require("dap.ui.widgets").hover()
end, { desc = "Hover Variables" })

-- Adapter Python Setup
dap.adapters.python = {
    type = "executable",
    command = "python",
    args = { "-m", "debugpy.adapter" },
}

-- Adapter Javascript Setup
dap.adapters["pwa-node"] = {
    type = "server",
    host = "localhost",
    port = "${port}",
    executable = {
        command = "node",
        -- Make sure to install js-debug-adapter using ( :MasonInstall js-debug-adapter ) command
        args = {
            vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
            "${port}",
        },
    },
}

dap.configurations = {
	java = {
		{
			type = "java",
			request = "attach",
			name = "Attach to the process",
			hostName = "localhost",
			port = "8000",
		},
	},
	python = {
		{
			type = "python",
			request = "launch",
			name = "Launch a debugging session",
			program = "${file}",
			console = "integratedTerminal",
			pythonPath = function()
				return "python"
			end,
		},
	},
	javascript = {
		{
			type = "pwa-node",
			request = "launch",
			name = "Launch file",
			program = "${file}",
			console = "integratedTerminal",
			cwd = "${workspaceFolder}",
		},
	},

}

