--- mini AI ---
-- require("mini.ai").setup({ n_lines = 500 })      -- better text objects: vin, van, vaf, vac

--- mini comment ---
-- Toggle comment on current line using 'gcc'
-- Toggle comment on visual selection using 'gc'
require("mini.comment").setup({})

--- mini move ---
-- require("mini.move").setup({})                   -- Alt-hjkl to move selection

--- mini cursorword ---
-- require("mini.cursorword").setup({})             -- highlight word under cursor

--- mini surround ---
-- Default Keymaps
-- | `sa` | Add surrounding or Direct with 'saiw' |
-- | `sd` | Delete surrounding |
-- | `sr` | Replace surrounding |
-- | `sf` | Find surrounding (right) |
-- | `sF` | Find surrounding (left) |
-- | `sh` | Highlight surrounding |
-- | `sn` | Update n_lines |
-- | `l` / `n` | as suffix for prev/next |
-- require("mini.surround").setup({})

--- mini indentscope ---
require("mini.indentscope").setup({
  symbol = '┊', --"│"
  options = { try_as_border = true },

})

--- mini pairs ---
require("mini.pairs").setup({}) -- auto-close brackets

--- mini trailspace ---
require("mini.trailspace").setup({}) -- highlight trailing whitespace

--- Turn MiniPick into your VS Code Command Palette ---
local MiniPick = require("mini.pick")
local MiniExtra = require("mini.extra")

MiniPick.setup()
MiniExtra.setup()

-- Files
vim.keymap.set("n", "<leader>pf", function()
  MiniPick.builtin.files()
end, { desc = "Mini File Picker" })

-- VS Code Ctrl+Shift+F equivalent
vim.keymap.set("n", "<leader>pg", function()
  MiniPick.builtin.grep_live()
end, {
  desc = "Live grep",
})

vim.keymap.set("n", "<leader>ps", function()
    MiniPick.builtin.grep({ pattern = vim.fn.expand("<cword>") })
  end, { desc = "Grep word/Search word"
})

-- Open buffers
vim.keymap.set("n", "<leader>pb", function()
  MiniPick.builtin.buffers()
end, {
  desc = "Buffers",
})

-- Recent files
vim.keymap.set("n", "<leader>pr", function()
  MiniExtra.pickers.oldfiles({
    current_dir = true,
  })
end, {
  desc = "Recent files",
})

-- VS Code Command Palette equivalent
vim.keymap.set("n", "<leader>pc", function()
  MiniExtra.pickers.commands()
end, {
  desc = "Command palette",
})

-- Search keymaps
vim.keymap.set("n", "<leader>pk", function()
  MiniExtra.pickers.keymaps()
end, {
  desc = "Keymaps",
})

-- Diagnostics
vim.keymap.set("n", "<leader>xx", function()
  MiniExtra.pickers.diagnostic({
    scope = "all",
  })
end, {
  desc = "Workspace diagnostics",
})

vim.keymap.set("n", "<leader>xb", function()
  MiniExtra.pickers.diagnostic({
    scope = "current",
  })
end, {
  desc = "Buffer diagnostics",
})

-- Document symbols
vim.keymap.set("n", "<leader>ss", function()
  MiniExtra.pickers.lsp({
    scope = "document_symbol",
  })
end, {
  desc = "Document symbols",
})

-- Workspace symbols
vim.keymap.set("n", "<leader>sS", function()
  MiniExtra.pickers.lsp({
    scope = "workspace_symbol_live",
  })
end, {
  desc = "Workspace symbols",
})

-- LSP references
vim.keymap.set("n", "<leader>sr", function()
  MiniExtra.pickers.lsp({
    scope = "references",
  })
end, {
  desc = "References",
})

--- Better buffer management ---
local MiniBufremove = require("mini.bufremove")
MiniBufremove.setup()

vim.keymap.set("n", "<leader>bd", function()
  MiniBufremove.delete()
end, {
  desc = "Delete buffer",
})

vim.keymap.set("n", "<leader>bD", function()
  MiniBufremove.delete(0, true)
end, {
  desc = "Force delete buffer",
})

--- Project sessions ---
local MiniSessions = require("mini.sessions")
MiniSessions.setup()

vim.keymap.set("n", "<leader>sw", function()
  MiniSessions.write("Session.vim")
end, {
  desc = "Save session",
})

vim.keymap.set("n", "<leader>sl", function()
  MiniSessions.read("Session.vim")
end, {
  desc = "Load session",
})

vim.keymap.set("n", "<leader>sd", function()
  MiniSessions.delete("Session.vim")
end, {
  desc = "Delete session",
})

--- mini.diff ---
local MiniDiff = require("mini.diff")

MiniDiff.setup({
  view = {
    style = "sign",

    signs = {
      add = "+",
      change = "~",
      delete = "-",
    },
  },

  mappings = {
    apply = "gh",
    reset = "gH",

    textobject = "gh",

    goto_first = "[H",
    goto_prev = "[h",
    goto_next = "]h",
    goto_last = "]H",
  },

  options = {
    algorithm = "histogram",
    indent_heuristic = true,
    linematch = 60,
    wrap_goto = true,
  },
})


--- mini.git ---
local MiniGit = require("mini.git")

MiniGit.setup({
  job = {
    git_executable = "git",
    timeout = 30000,
  },

  command = {
    split = "auto",
  },
})


--- Git mappings ---
vim.keymap.set("n", "<leader>gd", function()
  MiniDiff.toggle_overlay()
end, {
  desc = "Git diff overlay",
})


vim.keymap.set("n", "<leader>gD", function()
  MiniDiff.toggle()
end, {
  desc = "Git toggle diff",
})


vim.keymap.set("n", "<leader>gs", "<cmd>Git status<cr>", {
  desc = "Git status",
})


vim.keymap.set(
  "n",
  "<leader>gl",
  "<cmd>Git log --oneline --graph --decorate<cr>",
  {
    desc = "Git log",
  }
)


vim.keymap.set("n", "<leader>gb", "<cmd>Git branch<cr>", {
  desc = "Git branches",
})


vim.keymap.set(
  "n",
  "<leader>gB",
  "<cmd>vertical Git blame -- %<cr>",
  {
    desc = "Git blame",
  }
)


vim.keymap.set("n", "<leader>gc", "<cmd>Git commit<cr>", {
  desc = "Git commit",
})


vim.keymap.set("n", "<leader>gp", "<cmd>Git push<cr>", {
  desc = "Git push",
})


vim.keymap.set("n", "<leader>gP", "<cmd>Git pull<cr>", {
  desc = "Git pull",
})


vim.keymap.set("n", "<leader>gi", function()
  MiniGit.show_at_cursor()
end, {
  desc = "Git info at cursor",
})
