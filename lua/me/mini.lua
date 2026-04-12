require("mini.ai").setup({ n_lines = 500 })         -- better text objects: vin, van, vaf, vac

require("mini.comment").setup({})                   -- gcc to commect, go in visual

-- require("mini.move").setup({})                      -- Alt-hjkl to move selection

-- require("mini.surround").setup({
--     mappings = {
--         add            = "sa",
--         delete         = "sd",
--         find           = "sf",
--         find_left      = "sF",
--         highlight      = "sh",
--         replace        = "sr",
--         update_n_lines = "sn",
--     },
-- })

require("mini.cursorword").setup({})                -- highlight word under cursor

require("mini.indentscope").setup({
    symbol = '┊', --"│"
    options = { try_as_border = true },

})

require("mini.pairs").setup({})                     -- auto-close brackets

require("mini.trailspace").setup({})                -- highlight trailing whitespace

-- require("mini.bufremove").setup({})
-- require("mini.notify").setup({})
-- require("mini.icons").setup({})                     -- file icons

