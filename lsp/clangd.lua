---@type vim.lsp.Config
return {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--completion-style=detailed",
  },

  filetypes = {
    "c",
    "cpp",
    "objc",
    "objcpp",
  },

  root_markers = {
    ".clangd",
    "compile_commands.json",
    "compile_flags.txt",
    ".git",
  },
}
