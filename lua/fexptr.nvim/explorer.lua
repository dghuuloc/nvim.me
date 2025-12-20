local api = vim.api
local fn  = vim.fn
local uv  = vim.loop

local config = require("fexptr.config").values
local state  = require("fexptr.state")

local M = {}

-- ====================================================================================
-- FS Helpers

local function scandir(path)
    local handle = uv.fs_scandir(path)
    if not handle then return {} end

    local items = {}
    while true do
        local name, t = uv.fs_scandir_next(handle)
        if not name then break end
        if config.show_hidden or name:sub(1,1) ~= "." then
            items[#items+1] = { name = name, type = t }
        end
    end

    table.sort(items, function(a,b)
        if a.type == b.type then return a.name < b.name end
        return a.type == "directory"
    end)

    return items
end

-- ====================================================================================
-- Recursive copy

local function copy_recursive(src, dest)
    local stat = uv.fs_stat(src)
    if not stat then return end

    if stat.type == "file" then
        fn.mkdir(fn.fnamemodify(dest, ":h"), "p")
        local data = assert(io.open(src, "rb")):read("*all")
        local f = assert(io.open(dest, "wb"))
        f:write(data)
        f:close()
    else
        fn.mkdir(dest, "p")
        for _, item in ipairs(scandir(src)) do
            copy_recursive(src .. "/" .. item.name, dest .. "/" .. item.name)
        end
    end
end

-- ====================================================================================
-- Tree builder

local function build_tree(path, depth)
    depth = depth or 0
    local nodes = {}

    for _, item in ipairs(scandir(path)) do
        local full = path .. "/" .. item.name
        if item.type == "directory" then
            nodes[#nodes+1] = {
                name = item.name,
                path = full,
                depth = depth,
                is_dir = true,
            }
            if state.expanded[full] then
                vim.list_extend(nodes, build_tree(full, depth + 1))
            end
        else
            nodes[#nodes+1] = {
                name = item.name,
                path = full,
                depth = depth,
                is_dir = false,
            }
        end
    end

    return nodes
end

-- ====================================================================================
-- Render

local function render()
    if not state.buf then return end

    state.cursor = api.nvim_win_get_cursor(state.win)
    state.tree = build_tree(state.root)

    local lines = { "~ " .. fn.fnamemodify(state.root, ":t"):upper() }

    for _, node in ipairs(state.tree) do
        local indent = string.rep("  ", node.depth)
        local icon = node.is_dir
            and (state.expanded[node.path] and config.icons.folder_open or config.icons.folder_closed)
            or config.icons.file

        lines[#lines+1] = indent .. icon .. " " .. node.name
    end

    api.nvim_buf_set_option(state.buf, "modifiable", true)
    api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    api.nvim_buf_set_option(state.buf, "modifiable", false)

    pcall(api.nvim_win_set_cursor, state.win, state.cursor)
end

-- ====================================================================================
-- Node helpers

local function get_node()
    local row = api.nvim_win_get_cursor(0)[1]
    if row <= 1 then return nil end
    return state.tree[row - 1]
end

-- ====================================================================================
-- Actions

function M.open()
    local node = get_node()
    if not node then return end

    if node.is_dir then
        state.expanded[node.path] = not state.expanded[node.path]
        vim.g.fexptr_expanded = state.expanded
        render()
    else
        vim.cmd("wincmd l")
        vim.cmd("edit " .. fn.fnameescape(node.path))
    end
end

function M.toggle()
    if state.win and api.nvim_win_is_valid(state.win) then
        api.nvim_win_close(state.win, true)
        state.win, state.buf = nil, nil
        return
    end

    state.buf = api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype = "nofile"
    vim.bo[state.buf].bufhidden = "wipe"
    vim.bo[state.buf].swapfile = false

    vim.cmd("topleft " .. config.width .. "vsplit")
    state.win = api.nvim_get_current_win()
    api.nvim_win_set_buf(state.win, state.buf)

    vim.wo[state.win].number = false
    vim.wo[state.win].relativenumber = false
    vim.wo[state.win].signcolumn = "no"

    local map = function(lhs, rhs)
        vim.keymap.set("n", lhs, rhs, { buffer = state.buf, silent = true })
    end

    map("<CR>", M.open)
    map("o", M.open)
    map("q", M.toggle)

    render()
end

return M
