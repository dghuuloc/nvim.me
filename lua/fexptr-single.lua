
-- ====================================================================================
-- Fexptr: Native Neovim File Explorer (Single File Test)
-- Author: dghuuloc
-- Neovim: 0.11+
-- ====================================================================================

local api = vim.api
local fn  = vim.fn
local uv  = vim.loop

-- ====================================================================================
-- Config
local config = {
    width = 30,
    show_hidden = false,
    icons = {
        folder_closed = "",
        folder_open   = "",
        file          = "󰈙",
    },
}

local M = {}

function M.setup(opts)
    config = vim.tbl_deep_extend("force", config, opts or {})
end

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
    expanded = vim.g.fexptr_expanded or {},
    clipboard = nil,
    cursor = {1,0},
}

-- ====================================================================================
-- FS Helpers

---@param path string
---@return { name: string, type: string }[]
local function scandir(path)
    local handle = uv.fs_scandir(path)
    if not handle then return {} end

    local items = {}
    while true do
        local name, t = uv.fs_scandir_next(handle)
        if not name then break end
        if config.show_hidden or name:sub(1,1) ~= "." then
            items[#items+1] = {name=name,type=t}
        end
    end

    table.sort(items, function(a,b)
        if a.type == b.type then return a.name < b.name end
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
            local names = {item.name}

            while true do
                local children = scandir(current)
                if #children ~= 1 or children[1].type ~= "directory" then break end
                current = current .. "/" .. children[1].name
                names[#names+1] = children[1].name
            end

            nodes[#nodes+1] = {
                name = table.concat(names, "/"),
                path = current,
                depth = depth,
                is_dir = true,
            }

            if state.expanded[current] then
                vim.list_extend(nodes, build_tree(current, depth+1))
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

    local lines = {"~ " .. fn.fnamemodify(state.root, ":t"):upper()}
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
-- Node Helpers

---@return ExplorerNode|nil
local function get_node()
    local row = api.nvim_win_get_cursor(0)[1]
    if row <= 1 then return nil end
    return state.tree[row-1]
end

---@return string
-- local function base_path()
--     local node = get_node()
--     if not node then return state.root end
--     return node.is_dir and node.path or fn.fnamemodify(node.path, ":h")
-- end

-- ====================================================================================
-- Actions

local function open_in_right(path)
    -- vim.cmd("wincmd l")
    -- vim.cmd("edit " .. fn.fnameescape(path))
    api.nvim_set_current_win(state.win)
    vim.cmd("wincmd l")
    if api.nvim_get_current_win() == state.win then
        vim.cmd("vsplit | wincmd l")
    end
    vim.cmd("edit " .. fn.fnameescape(path))

end

function M.open()
    local node = get_node()
    if not node then return end
    if node.is_dir then
        state.expanded[node.path] = not state.expanded[node.path]
        vim.g.fexptr_expanded = state.expanded
        render()
    else
        open_in_right(node.path)
    end
end

function M.create_()
    local node = get_node()
    local base

    if node and node.is_dir then
        base = node.path
    else
        base = state.root
    end

    -- Ensure base path ends without trailing slash
    base = base:gsub("[/\\]$", "")

     -- Convert to path relative to root for display in input
    local rel_base = vim.fn.fnamemodify(base, ":.")
    rel_base = rel_base:gsub("\\", "/")

    -- Pre-fill input with the current node's full path + "/"
    local input = fn.input("Create (relative to root): ", rel_base .. "/")
    if input == "" then return end

    -- Convert input back to absolute path
    local abs_path = state.root .. "/" .. input
    abs_path = abs_path:gsub("[/\\]+", "/") -- normalize slashes

    -- If ends with "/", create directory
    if input:sub(-1) == "/" then
        fn.mkdir(input, "p")
    else
        fn.mkdir(fn.fnamemodify(input, ":h"), "p")
        local fd = uv.fs_open(input, "w", 420)
        if fd then uv.fs_close(fd) end
    end

    render()
end

function M.rename_()
    local node = get_node()
    if not node then return end

    local rel_path = vim.fn.fnamemodify(node.path, ":.")
    rel_path = rel_path:gsub("\\", "/")
    local input = vim.fn.input("Rename (relative to root): ", rel_path)
    if input == "" then return end

     -- Normalize paths
    local abs_old = node.path:gsub("\\", "/")
    local abs_new = (state.root .. "/" .. input):gsub("\\", "/"):gsub("/+", "/")

    local abs_new_parent = vim.fn.fnamemodify(abs_new, ":h")
    if not vim.loop.fs_stat(abs_new_parent) then
        vim.fn.mkdir(abs_new_parent, "p")
    end

    if vim.loop.fs_stat(abs_new) then
        vim.notify("Target already exists: " .. abs_new, vim.log.levels.ERROR)
        return
    end

    -- Attempt to rename (works for files and empty directories)
    local ok, err = uv.fs_rename(abs_old, abs_new)
    if not ok then
        vim.notify("Rename failed: " .. tostring(err), vim.log.levels.ERROR)
        return
    end

    -- Refresh the tree
    render()
end

function M.delete_()
    local node = get_node()
    if not node then return end
    if fn.confirm("Delete "..node.name.."?", "&Yes\n&No") ~= 1 then return end
    if node.is_dir then fn.delete(node.path, "rf") else uv.fs_unlink(node.path) end
    render()
end

function M.copy(cut)
    local node = get_node()
    if node then state.clipboard = {path=node.path, cut=cut} end
end

-- ===========================
function M.paste_()
    if not state.clipboard then return end

    -- Pre-fill target input with current node path relative to root
    local node = get_node()
    local target_base = node and node.is_dir and node.path or state.root
    local rel_target = vim.fn.fnamemodify(target_base, ":.")
    rel_target = rel_target:gsub("\\", "/")

    local input = fn.input("Paste to (relative to root): ", rel_target .. "/")
    if input == "" then return end

    -- Absolute path
    local target_dir = state.root .. "/" .. input
    target_dir = target_dir:gsub("[/\\]+", "/")

    -- Target full path
    local target = target_dir .. "/" .. fn.fnamemodify(state.clipboard.path, ":t")
    target = target:gsub("[/\\]+", "/")

    -- Prevent moving folder into itself
    if state.clipboard.cut and target:sub(1,#state.clipboard.path) == state.clipboard.path then
        vim.notify("Cannot move directory into itself", vim.log.levels.ERROR)
        return
    end

    fn.mkdir(fn.fnamemodify(target, ":h"), "p")

    if state.clipboard.cut then
        local ok, err = pcall(uv.fs_rename, state.clipboard.path, target)
        if not ok then
            vim.notify("Move failed: " .. err .. "\nTrying copy + delete...", vim.log.levels.WARN)
            -- fallback: copy + delete
            copy_recursive(state.clipboard.path, target)
            uv.fs_rmdir(state.clipboard.path)
        end
        state.clipboard = nil
    else
        copy_recursive(state.clipboard.path, target)
    end

    render()
end

-- ====================================================================================
-- Toggle / Setup
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

    vim.cmd("topleft "..config.width.."vsplit")
    state.win = api.nvim_get_current_win()
    api.nvim_win_set_buf(state.win, state.buf)
    vim.wo[state.win].number = false
    vim.wo[state.win].relativenumber = false
    vim.wo[state.win].signcolumn = "no"

    local map = function(lhs, rhs)
        vim.keymap.set("n", lhs, rhs, {buffer=state.buf,silent=true})
    end

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
