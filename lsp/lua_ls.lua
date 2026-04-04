---@type vim.lsp.Config
return {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = {
        { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua", "stylua.toml", "selene.toml", "selene.yml" },
        ".git",
    },
    settings = {
        Lua = {
            runtime = {
                version = "Lua 5.4",
            },
            completion = {
                enable = true,
            },
            diagnostics = {
                enable = true,
                globals = { "vim" },
            },
            workspace = {
                library = { vim.env.VIMRUNTIME },
                -- library = vim.api.nvim_get_runtime_file("", true)
                checkThirdParty = false,
            },
       },
   },
}
