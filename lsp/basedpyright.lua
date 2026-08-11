---@type vim.lsp.Config
return {
  cmd = { "basedpyright-langserver", "--stdio" },

  filetypes = { "python" },

  root_markers = {
    "pyrightconfig.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    ".git",
  },

  before_init = function(_, config)
    local root = config.root_dir

    if not root then
      return
    end

    local is_windows = vim.fn.has("win32") == 1
    local python

    if is_windows then
      python = vim.fs.joinpath(
        root,
        ".venv",
        "Scripts",
        "python.exe"
      )
    else
      python = vim.fs.joinpath(
        root,
        ".venv",
        "bin",
        "python"
      )
    end

    if vim.uv.fs_stat(python) then
      config.settings = vim.tbl_deep_extend(
        "force",
        config.settings or {},
        {
          python = {
            pythonPath = python,
          },
        }
      )
    end
  end,

  settings = {
    basedpyright = {
      analysis = {
        autoImportCompletions = true,
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true,

        inlayHints = {
          variableTypes = true,
          functionReturnTypes = true,
          callArgumentNames = true,
          callArgumentNamesMatching = false,
          genericTypes = true,
        },
      },
    },
  },
}
