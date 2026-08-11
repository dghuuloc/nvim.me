-- ── nvim-treesitter ──────────────────────────────────────────────────────
local ok, nts = pcall(require, "nvim-treesitter")
if not ok then
    return
end

nts.setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
})

local parsers = {
    "vim", "vimdoc", "markdown", "markdown_inline",
    "java", "python", "typescript", "javascript", "rust", "lua", "sql",
    "c", "cpp",
    "tsx", "html", "css", "query", "dockerfile",
    "json", "yaml", "toml", "bash"
}

vim.api.nvim_create_user_command("TSInstallMyParsers", function()
    nts.install(parsers)
end, { desc = "Install my Treesitter parsers" })

local group = vim.api.nvim_create_augroup("MyTreeSitter", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "*",

    callback = function(ev)
        local ft = vim.bo[ev.buf].filetype
        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
            return
        end

        local ok_lang = vim.treesitter.language.add(lang)
        if not ok_lang then
            return
        end

        if vim.treesitter.query.get(lang, "highlights") then
            pcall(vim.treesitter.start, ev.buf, lang)
        end

        if vim.treesitter.query.get(lang, "indents") then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
    end,

})
