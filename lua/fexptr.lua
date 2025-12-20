-- ====================================================================================
-- Fexptr: Native Neovim File Explorer
-- Author: dghuuloc
-- Neovim: 0.11+
-- ====================================================================================

local M = {}

local api = vim.api
local fn  = vim.fn
local uv  = vim.loop

-- ====================================================================================
-- State

---@type {
---  root: string,
---  win: number|nil,
---  buf: number|nil,
---  tree: ExplorerNode[],
---  expanded: table<string, boolean>,
---  clipboard: Clipboard|nil
---}
local state = {
    root = uv.cwd(),
    win = nil,
    buf = nil,
    tree = {},
    expanded = vim.g.native_explorer_expanded or {},
    clipboard = nil,
}

-- ====================================================================================
-- Helpers

---@return boolean
local function is_open()
    return state.win and api.nvim_win_is_valid(state.win)
        and state.buf and api.nvim_buf_is_valid(state.buf)
end

---@param path string
---@return { name: string, type: string }[]
local function scandir(path)
    local handle = uv.fs_scandir(path)
    if not handle then return {} end

    local items = {}
    while true do
        local name, t = uv.fs_scandir_next(handle)
        if not name then break end
        table.insert(items, { name = name, type = t })
    end

    table.sort(items, function(a,b)
        if a.type == b.type then 
            return a.name < b.name
        end
        return a.type == "directory"
    end)

    return items
end

-- ====================================================================================
-- Recursive copy (Windows-safe)

---@param src string
---@param dest string
local function copy_recursive(src, dest)
    local stat = uv.fs_stat(src)
    if not stat then return end

    if stat.type == "file" then
        fn.mkdir(fn.fnamemodify(dest, ":h"), "p")
        local data = assert(io.open(src, "rb")):read("*all")
        local f = assert(io.open(dest, "wb"))
        f:write(data)
        f:close()
    elseif stat.type == "directory" then
        fn.mkdir(dest, "p")
        for _, item in ipairs(scandir(src)) do
            copy_recursive(src .. "/" .. item.name, dest .. "/" .. item.name)
        end
    end
end

-- ====================================================================================
-- Tree builder (collapsed directories, UI only)

---@param path string
---@param depth number
---@return ExplorerNode[]
local function build_tree(path, depth)
    depth = depth or 0
    local nodes = {}

    local ok, items = pcall(scandir, path)
    if not ok or not items then return nodes end

    for _, item in ipairs(items) do
        local full = path .. "/" .. item.name

        if item.type == "directory" then
            local current = full
            local name_chain = { item.name }

            while true do
                local items = scandir(current)
                if #items ~= 1 or items[1].type ~= "directory" then
                    break
                end
                current = current .. "/" .. items[1].name
                name_chain[#name_chain + 1] = items[1].name
            end

            --table.insert(nodes, {
            nodes[#nodes + 1] = {
                name = table.concat(name_chain, "/"),
                path = current,
                depth = depth,
                is_dir = true,
            }
            --})

            if state.expanded[current] then
                vim.list_extend(nodes, build_tree(current, depth + 1))
            end
        else
            nodes[#nodes + 1] = {
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
    state.tree = build_tree(state.root) or {}

    local lines = {
        "~ " .. fn.fnamemodify(state.root, ":t"):upper()
    }

    for _, node in ipairs(state.tree) do
        local indent = string.rep("  ", node.depth)
        local icon = node.is_dir
            and (state.expanded[node.path] and "" or "")
            or "󰈙"

        lines[#lines + 1] = indent .. icon .. " " .. node.name
    end

    api.nvim_buf_set_option(state.buf, "modifiable", true)
    api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    api.nvim_buf_set_option(state.buf, "modifiable", false)

end

-- ====================================================================================
-- Node helper

---@return ExplorerNode|nil
local function get_node()
    local row = api.nvim_win_get_cursor(0)[1]
    if row == 1 then return nil end
    return state.tree[row - 1]
end

---@return string
local function get_base_path()
    local node = get_node()
    if not node then return state.root end
    if node.is_dir then return node.path end
    return fn.fnamemodify(node.path, ":h")
end

-- ====================================================================================
-- Open file in RIGHT window

---@param path string
local function open_in_right_window(path)
    api.nvim_set_current_win(state.win)
    vim.cmd("wincmd l")
    if api.nvim_get_current_win() == state.win then
        vim.cmd("vsplit | wincmd l")
    end
    vim.cmd("edit " .. fn.fnameescape(path))
end

-- ====================================================================================
-- Actions

function M.open()
    local node = get_node()
    if not node then return end

    if node.is_dir then
        state.expanded[node.path] = not state.expanded[node.path]
        vim.g.native_explorer_expanded = state.expanded
        render()
    else
        open_in_right_window(node.path)
    end
end

-- Create file or folder
function M.create_()
    local base = get_base_path()
    local name = fn.input("Create: ")
    if name == "" then return end

    local path = base .. "/" .. name

    if name:sub(-1) == "/" then
        fn.mkdir(path, "p")
    else
        fn.mkdir(fn.fnamemodify(path, ":h"), "p")
        local fd = uv.fs_open(path, "w", 420)
        if fd then uv.fs_close(fd) end
    end

    render()
end

-- Rename file or folder
function M.rename_()
    local node = get_node()
    if not node then return end

    -- Ask for NEW PATH (absolute)
    local new_path = fn.input("Rename to: ", node.path)
    if new_path == "" or new_path == node.path then return end

    -- Normalize slashes (important on Windows)
    new_path = fn.fnamemodify(new_path, ":p")
    local old_path = fn.fnamemodify(node.path, ":p")

    -- Destination must NOT exist
    if uv.fs_stat(new_path) then
        vim.notify("Target already exists", vim.log.levels.ERROR)
        return
    end

    -- Ensure parent directory exists
    fn.mkdir(fn.fnamemodify(new_path, ":h"), "p")

    local ok, err = uv.fs_rename(old_path, new_path)
    if not ok then
        vim.notify("Rename failed:" .. tostring(err), vim.log.levels.ERROR)
        return
    end

    render()
end

-- Delete file or folder
function M.delete_()
    local node = get_node()
    if not node then return end

    if fn.confirm("Delete " .. node.name .. "?", "&Yes\n&No") ~= 1 then return end

    if node.is_dir then
        fn.delete(node.path, "rf")
    else
        uv.fs_unlink(node.path)
    end

    render()
end

-- Copy file or folder
function M.copy_(cut)
    local node = get_node()
    if not node then return end
    state.clipboard = { path = node.path, cut = cut }
end

-- Paste file or folder
function M.paste_()
    if not state.clipboard then return end

    local dest_dir = get_base_path()
    local target = dest_dir .. "/" .. fn.fnamemodify(state.clipboard.path, ":t")

    if target:sub(1, #state.clipboard.path) == state.clipboard.path then
        vim.notify("Cannot move directory into itself", vim.log.levels.ERROR)
        return
    end

    if state.clipboard.cut then
        fn.mkdir(fn.fnamemodify(target, ":h"), "p")
        uv.fs_rename(state.clipboard.path, target)
        state.clipboard = nil
    else
        copy_recursive(state.clipboard.path, target)
    end

    render()
end

-- ====================================================================================
-- Toggle
function M.toggle()
    if is_open() then
        api.nvim_win_close(state.win, true)
        state.win, state.buf = nil, nil
        return
    end

    state.buf = api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype = "nofile"
    vim.bo[state.buf].bufhidden = "wipe"
    vim.bo[state.buf].swapfile = false

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
    map("a", M.create_)
    map("r", M.rename_)
    map("d", M.delete_)
    map("y", function() M.copy_(false) end)
    map("x", function() M.copy_(true) end)
    map("p", M.paste_)
    map("q", M.toggle)

    render()
end

return M
