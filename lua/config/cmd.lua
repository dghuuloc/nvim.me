local util = require("config.util")

-- Set up colorscheme
vim.cmd.colorscheme('nord')

-- Get h and l for moving over next lines or previous lines
vim.cmd([[set whichwrap+=<,>,[,],h,l]])

-- Prevent neovim commenting out next line after a comment line
vim.api.nvim_create_autocmd("FileType", {
    pattern = "*",
    callback = function()
        vim.opt_local.formatoptions:remove({ "r", "o" })
    end,
})

-- Dap-float FileType
vim.api.nvim_create_autocmd("FileType", {
    pattern = "dap-float",
    callback = function()
        vim.api.nvim_buf_set_keymap(0, "n", "q", "<cmd>close!<CR>", { noremap = true, silent = true })
    end,
})

-- Create user commands
vim.api.nvim_create_user_command("MavenNewProject", util.maven_new_project, { desc = "Create New Maven Project" })
vim.api.nvim_create_user_command("MavenRun", util.maven_run_project, { desc = "Run Maven Project" })
vim.api.nvim_create_user_command("MavenTask", util.maven_task_project, { desc = "Execute Maven Task" })
vim.api.nvim_create_user_command("MavenNewClass", util.create_java_class, { desc = "Create Java Class" })
vim.api.nvim_create_user_command("MavenNewInterface", util.create_java_interface, { desc = "Create Java Interface" })
vim.api.nvim_create_user_command("JavaRun", util.java_run_project, { desc = "Run Java Project" })
