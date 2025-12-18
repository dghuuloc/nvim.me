-- lua/native_explorer.lua
-- Native Neovim File Explorer (NO plugins)
-- nvim-tree–like behavior: colorscheme-aware, toggleable, fixed root

local M = {}

local api = vim.api
local fn  = vim.fn
local uv  = vim.loop

-- =========================
-- State
-- =========================
local state = {
    root = uv.cwd(),
    win = nil,          -- explorer window
    buf = nil,          -- explorer buffer
    tree = {},
    expanded = {},
    clipboard = nil,
}

-- =========================
-- Helpers
-- =========================
local function is_open()
    return state.win
        and api.nvim_win_is_valid(state.win)
        and state.buf
        and api.nvim_buf_is_valid(state.buf)
end

local function scandir(path)
    local handle = uv.fs_scandir(path)
    if not handle then return {} end

    local items = {}
    while true do
        local name, t = uv.fs_scandir_next(handle)
        if not name then break end
        table.insert(items, { name = name, type = t })
    end

    table.sort(items, function(a, b)
        if a.type == b.type then return a.name < b.name end
        return a.type == "directory"
    end)

    return items
end

-- group_empty = true
local function collapse_dir(path)
    local current = path
    while true do
        local handle = uv.fs_scandir(current)
        if not handle then break end

        local name, t = uv.fs_scandir_next(handle)
        if not name then break end

        local next_name = uv.fs_scandir_next(handle)
        if next_name then break end

        if t == "directory" then
            current = current .. "/" .. name
        else
            break
        end
    end
    return current
end

-- =========================
-- Tree
-- =========================
local function build_tree(path, depth)
    depth = depth or 0
    local nodes = {}

    for _, item in ipairs(scandir(path)) do
        local full = path .. "/" .. item.name

        if item.type == "directory" then
            local collapsed = collapse_dir(full)
            table.insert(nodes, {
                name = fn.fnamemodify(collapsed, ":t"),
                path = collapsed,
                depth = depth,
                is_dir = true,
            })
            if state.expanded[collapsed] then
                vim.list_extend(nodes, build_tree(collapsed, depth + 1))
            end
        else
            table.insert(nodes, {
                name = item.name,
                path = full,
                depth = depth,
                is_dir = false,
            })
        end
    end

    return nodes
end

-- =========================
-- Render
-- =========================
local function render()
    if not state.buf then return end
    
    state.tree = build_tree(state.root)
    local lines = {}

    -- root label
    table.insert(lines, "~ " .. string.upper(fn.fnamemodify(state.root, ":t")))

    for _, node in ipairs(state.tree) do
        local indent = string.rep("  ", node.depth)
        local icon = node.is_dir
            and (state.expanded[node.path] and "" or "")
            or "󰈙"

        table.insert(lines, indent .. icon .. " " .. node.name)
    end

    api.nvim_buf_set_option(state.buf, "modifiable", true)
    api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    api.nvim_buf_set_option(state.buf, "modifiable", false)
end

-- =========================
-- Node helper
-- =========================
local function get_node()
    local row = api.nvim_win_get_cursor(0)[1]
    if row == 1 then return nil end
    return state.tree[row - 1]
end

-- =========================
-- Open file in RIGHT window
-- =========================
local function open_in_right_window(path)
    if not state.win or not api.nvim_win_is_valid(state.win) then
        return
    end

    -- go to explorer
    api.nvim_set_current_win(state.win)

    -- try right window
    vim.cmd("wincmd l")
    local target = api.nvim_get_current_win()

    -- if no right window, create one
    if target == state.win then
        vim.cmd("vsplit")
        vim.cmd("wincmd l")
        target = api.nvim_get_current_win()
    end

    api.nvim_set_current_win(target)
    vim.cmd("edit " .. fn.fnameescape(path))
end

-- =========================
-- Actions
-- =========================
function M.open()
    local node = get_node()
    if not node then return end

    if node.is_dir then
        state.expanded[node.path] = not state.expanded[node.path]
        render()
    else
        open_in_right_window(node.path)
        -- vim.cmd("edit " .. fn.fnameescape(node.path))
    end
end

-- create
function M.create()
    local node = get_node()
    local base = node and (node.is_dir and node.path or fn.fnamemodify(node.path, ":h")) or state.root
    local name = fn.input("Create: ")
    if name == "" then return end

    local path = base .. "/" .. name
    if name:sub(-1) == "/" then
        uv.fs_mkdir(path, 493)
    else
        uv.fs_open(path, "w", 420)
    end
    render()
end

-- rename
function M.rename()
    local node = get_node()
    if not node then return end
    local new = fn.input("Rename: ", node.name)
    if new == "" then return end
    uv.fs_rename(node.path, fn.fnamemodify(node.path, ":h") .. "/" .. new)
    render()
end

-- delete
function M.delete()
    local node = get_node()
    if not node then return end
    if fn.confirm("Delete " .. node.name .. "?", "&Yes\n&No") ~= 1 then return end
    if node.is_dir then fn.delete(node.path, "rf") else uv.fs_unlink(node.path) end
    render()
end

-- copy
function M.copy(cut)
    local node = get_node()
    if not node then return end
    state.clipboard = { path = node.path, cut = cut }
end

-- paste
function M.paste()
    if not state.clipboard then return end
    local node = get_node()
    local dest = node and (node.is_dir and node.path or fn.fnamemodify(node.path, ":h")) or state.root
    local target = dest .. "/" .. fn.fnamemodify(state.clipboard.path, ":t")

    if state.clipboard.cut then
        uv.fs_rename(state.clipboard.path, target)
        state.clipboard = nil
    else
        fn.system({ "cp", "-r", state.clipboard.path, target })
    end
    render()
end

-- =========================
-- Toggle (IMPORTANT)
-- =========================
function M.toggle()
    if is_open() then
        api.nvim_win_close(state.win, true)
        state.win = nil
        state.buf = nil
        return
    end

    state.buf = api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype = "nofile"
    vim.bo[state.buf].bufhidden = "wipe"
    vim.bo[state.buf].swapfile = false
    vim.bo[state.buf].filetype = "Explorer"

    vim.cmd("topleft 30vsplit")
    state.win = api.nvim_get_current_win()
    api.nvim_win_set_buf(state.win, state.buf)

    vim.wo[state.win].number = false
    vim.wo[state.win].relativenumber = false
    vim.wo[state.win].signcolumn = "no"

    local map = function(lhs, rhs)
        vim.keymap.set("n", lhs, rhs, { buffer = state.buf, silent = true })
    end

    -- mapping
    map("<CR>", M.open)
    map("o", M.open)
    map("a", M.create)
    map("r", M.rename)
    map("d", M.delete)
    map("y", function() M.copy(false) end)
    map("x", function() M.copy(true) end)
    map("p", M.paste)
    map("q", M.toggle)
    map("<leader>e", M.toggle)

    render()
end

return M
