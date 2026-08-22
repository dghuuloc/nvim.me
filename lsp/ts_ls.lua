---@type vim.lsp.Config

local format = {
  -- Indentation
  tabSize = 4,
  indentSize = 4,
  convertTabsToSpaces = true,
  indentStyle = "Smart",

  -- Spaces
  insertSpaceAfterCommaDelimiter = true,
  insertSpaceAfterKeywordsInControlFlowStatements = true,
  insertSpaceBeforeAndAfterBinaryOperators = true,
  insertSpaceAfterSemicolonInForStatements = true,
  insertSpaceBeforeFunctionParenthesis = false,

  -- Braces
  insertSpaceAfterOpeningAndBeforeClosingNonemptyBraces = true,

  -- Semicolons
  semicolons = "insert",

  -- Cleanup
  trimTrailingWhitespace = true,
}

return {
  cmd = {
    "typescript-language-server",
    "--stdio",
  },

  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },

  root_markers = {
    "tsconfig.json",
    "jsconfig.json",
    "package.json",
    ".git",
  },

  -- TypeScript server preferences
  init_options = {
    preferences = {
      quotePreference = "double",

      includeCompletionsForModuleExports = true,
      includeCompletionsForImportStatements = true,

      importModuleSpecifierPreference = "shortest",
    },
  },

  settings = {
    formattingOptions = {
      tabSize = 4,
      insertSpaces = true,
    },

    typescript = {
      format = format,
    },

    javascript = {
      format = format,
    },
  },
}
