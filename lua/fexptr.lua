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

---@class Word
---@field dir string Directory path of the node
---@field node string Node name
---@field link string|nil Symlink target (optional)
---@field extension string|nil File extension (optional)
---@field type number 0=file, 1=directory
---@field col number Column of node in buffer

--@type table
local state = {
    root = uv.cwd(),
    win = nil,          -- explorer window
    buf = nil,          -- explorer buffer
    tree = {},
    expanded = vim.g.native_explorer_expanded or {},
    clipboard = nil, -- { path = string, cut = boolean }
}

-- =========================
-- Highlights (colorscheme aware)
-- =========================
-- local function setup_highlights()
--     local hl = api.nvim_set_hl
--     hl(0, "ExplorerRoot",      { link = "Title" })
--     hl(0, "ExplorerDirectory",{ link = "Directory" })
--     hl(0, "ExplorerFile",     { link = "Normal" })
--     hl(0, "ExplorerIcon",     { link = "Special" })
--     hl(0, "ExplorerCursor",   { link = "Visual" })
-- end
-- 
-- setup_highlights()
-- 
-- api.nvim_create_autocmd("ColorScheme", {
--     callback = setup_highlights,
-- })
 
-- ====================================================================================
-- Helpers
---@return boolean
local function is_open()
    return state.win and api.nvim_win_is_valid(state.win)
        and state.buf and api.nvim_buf_is_valid(state.buf)
end

---@param path string
---@return Word[]
local function scandir(path)
    local handle = uv.fs_scandir(path)
    if not handle then return {} end

    local items = {}
    while true do
        local name, t = uv.fs_scandir_next(handle)
        if not name then break end
        table.insert(items, {
            name = name,
            type = t
        })
    end

    table.sort(items, function(a,b)
        if a.type == b.type then return a.name < b.name end
        return a.type == "directory"
    end)

    return items
end


-- ====================================================================================
-- Recursive copy (Windows-safe)
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
-- group_empty
-- local function collapse_dir(path)
--     local current = path
--     while true do
--         local handle = uv.fs_scandir(current)
--         if not handle then break end
-- 
--         local name, t = uv.fs_scandir_next(handle)
--         if not name then break end
-- 
--         if uv.fs_scandir_next(handle) then break end
-- 
--         if t == "directory" then
--             current = current .. "/" .. name
--         else
--             break
--         end
-- 
--         -- local next_name, next_type = uv.fs_scandir_next(handle)
--         -- if next_name or t ~= "directory" then break end
-- 
--         -- current = current .. "/" .. name
--     end
--     return current
-- end

-- =========================
-- Git status (minimal)
-- =========================
-- local function git_status(path)
--     if fn.isdirectory(".git") == 0 then return "" end
--     local out = fn.systemlist({ "git", "status", "--porcelain", path })
--     if #out == 0 then return "" end
--     return out[1]:sub(1, 2)
-- end
 
-- =========================
-- Tree
-- =========================
-- local function build_tree(path, depth)
--     depth = depth or 0
--     local nodes = {}
-- 
--     for _, item in ipairs(scandir(path)) do
--         local full = path .. "/" .. item.name
-- 
--         if item.type == "directory" then
--             local collapsed = collapse_dir(full)
--             table.insert(nodes, {
--                 name = fn.fnamemodify(collapsed, ":t"),
--                 path = collapsed,
--                 depth = depth,
--                 is_dir = true,
--             })
-- 
--             if state.expanded[collapsed] then
--                 vim.list_extend(nodes, build_tree(collapsed, depth + 1))
--             end
--         else
--             table.insert(nodes, {
--                 name = item.name,
--                 path = full,
--                 depth = depth,
--                 is_dir = false,
--             })
--         end
--     end
-- 
--     return nodes
-- end

-- local function build_tree(path, depth)
--     depth = depth or 0
--     local nodes = {}
-- 
--     local items = scandir(path)
--     for _, item in ipairs(items) do
--         local full = path .. "/" .. item.name
-- 
--         table.insert(nodes, {
--             name = item.name,
--             path = full,
--             depth = depth,
--             is_dir = item.type == "directory",
--         })
-- 
--         if item.type == "directory" and state.expanded[full] then
--             vim.list_extend(nodes, build_tree(full, depth + 1))
--         end
--     end
-- 
--     return nodes
-- end

-- ====================================================================================
-- Tree builder
---@param path string
---@param depth number
---@return Word[]
local function build_tree(path, depth)
    depth = depth or 0
    local nodes = {}

    local ok, items = pcall(scandir, path)
    if not ok or not items then return nodes end

    -- for _, item in ipairs(scandir(path)) do
    for _, item in ipairs(items) do
        local full = path .. "/" .. item.name

        if item.type == "directory" then
            local current = full
            local name_chain = { item.name }

            -- collapse single-child directories
            while true do
                local items = scandir(current)
                if #items ~= 1 or items[1].type ~= "directory" then break end
                table.insert(name_chain, items[1].name)
                current = current .. "/" .. items[1].name
            end

            table.insert(nodes, {
                name = table.concat(name_chain, "/"),
                path = current,
                depth = depth,
                is_dir = true,
            })

            if state.expanded[current] then
                vim.list_extend(nodes, build_tree(current, depth + 1))
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

-- ====================================================================================
-- Render
local function render()
    if not state.buf then return end
    state.tree = build_tree(state.root) or {}

    local lines = {}
    -- local highlights = {}

    -- root label
    table.insert(lines, "~ " .. string.upper(fn.fnamemodify(state.root, ":t")))
    -- table.insert(highlights, { line = 0, group = "ExplorerRoot", start = 0, finish = -1, })

    for _, node in ipairs(state.tree) do
        local indent = string.rep("  ", node.depth)
        local icon = node.is_dir
            and (state.expanded[node.path] and "" or "")
            or "󰈙"

        -- added git status
        -- local git = git_status(node.path)
        -- table.insert(lines, indent .. icon .. " " .. node.name .. " " .. git)
        table.insert(lines, indent .. icon .. " " .. node.name)

        -- CHECK HIGHLIGHT
        -- local row = i

        -- icon highlight
        -- table.insert(highlights, {
        --     line = row,
        --     group = "ExplorerIcon",
        --     start = #indent,
        --     finish = #indent + #icon + 1,
        -- })

        -- name highlight
        -- table.insert(highlights, {
        --     line = row,
        --     group = node.is_dir and "ExplorerDirectory" or "ExplorerFile",
        --     start = #indent + #icon + 2,
        --     finish = -1,
        -- })

    end

    api.nvim_buf_set_option(state.buf, "modifiable", true)
    api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
    api.nvim_buf_clear_namespace(state.buf, -1, 0, -1)

    -- for _, h in ipairs(highlights) do
    --     api.nvim_buf_add_highlight(
    --         state.buf, -1, h.group, h.line, h.start, h.finish
    --     )
    -- end
    
    api.nvim_buf_set_option(state.buf, "modifiable", false)

    -- Highlight current file
    -- local cur = fn.expand("%:p")
    -- if cur ~= "" then
    --     for i, node in ipairs(state.tree) do
    --         if node.path == cur then
    --             api.nvim_buf_add_highlight(
    --                 state.buf,
    --                 -1,
    --                 "Visual",
    --                 i,  -- +1 because root label
    --                 0,
    --                 -1
    --             )
    --         end
    --     end
    -- end
end

-- ====================================================================================
-- Node helper
local function get_node()
    local row = api.nvim_win_get_cursor(0)[1]
    if row == 1 then return nil end
    return state.tree[row - 1]
end

-- Base path helper 
local function get_base_path()
    local node = get_node()
    if not node then return state.root end
    if node.is_dir then return node.path end
    return fn.fnamemodify(node.path, ":h")
end

-- =========================
-- Open file in RIGHT window
-- =========================
-- local function open_in_right_window(path)
--     if not state.win or not api.nvim_win_is_valid(state.win) then
--         return
--     end
-- 
--     -- go to explorer
--     api.nvim_set_current_win(state.win)
-- 
--     -- try right window
--     vim.cmd("wincmd l")
--     local target = api.nvim_get_current_win()
-- 
--     -- if no right window, create one
--     if target == state.win then
--         vim.cmd("vsplit")
--         vim.cmd("wincmd l")
--         target = api.nvim_get_current_win()
--     end
-- 
--     api.nvim_set_current_win(target)
--     vim.cmd("edit " .. fn.fnameescape(path))
-- end

-- ====================================================================================
-- Open file in RIGHT window
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
        -- vim.cmd("edit " .. fn.fnameescape(node.path))
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
        fn.mkdir(fn.fnamemodify(path, ":h"), "p")         -- ensure parent directories exist
        local fd = uv.fs_open(path, "w", 420)
        if fd then uv.fs_close(fd) end
    end

    render()
end

-- Rename file or folder
function M.rename_()
    local node = get_node()
    if not node then return end
    local new = fn.input("Rename: ", node.name)
    if new == "" then return end

    -- uv.fs_rename(node.path, fn.fnamemodify(node.path, ":h") .. "/" .. new)
    local dest = fn.fnamemodify(node.path, ":h") .. "/" .. new
    fn.mkdir(fn.fnamemodify(dest, ":h"), "p")  -- ensure parent folder exists
    uv.fs_rename(node.path, dest)
    render()
end

-- Delete file or folder
function M.delete_()
    local node = get_node()
    if not node then return end
    if fn.confirm("Delete " .. node.name .. "?", "&Yes\n&No") ~= 1 then return end
    if node.is_dir then fn.delete(node.path, "rf") else uv.fs_unlink(node.path) end
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
    local node = get_node()
    local dest = node and (node.is_dir and node.path or fn.fnamemodify(node.path, ":h")) or state.root
    local target = dest .. "/" .. fn.fnamemodify(state.clipboard.path, ":t")

    if state.clipboard.cut then
        fn.mkdir(fn.fnamemodify(target, ":h"), "p") --added copy
        uv.fs_rename(state.clipboard.path, target)
        state.clipboard = nil
    else
        -- fn.system({ "cp", "-r", state.clipboard.path, target })
        copy_recursive(state.clipboard.path, target)
    end

    render()
end

-- ====================================================================================
-- Toggle
function M.toggle()
    if is_open() then
        api.nvim_win_close(state.win, true)
        state.win = nil
        state.buf = nil
        return
    end

    state.buf = api.nvim_create_buf(false, true)
    vim.bo[state.buf].buftype = 'nofile'
    vim.bo[state.buf].bufhidden = 'wipe'
    vim.bo[state.buf].swapfile = false
    vim.bo[state.buf].filetype = 'Explorer'

    vim.cmd('topleft 30vsplit')
    state.win = api.nvim_get_current_win()
    api.nvim_win_set_buf(state.win, state.buf)
    vim.wo[state.win].number = false
    vim.wo[state.win].relativenumber = false
    vim.wo[state.win].signcolumn = 'no'

    local map = function(lhs, rhs)
        vim.keymap.set('n', lhs, rhs, { buffer = state.buf, silent = true })
    end

    -- mapping
    map('<CR>', M.open)
    map('o', M.open)
    map('a', M.create_)
    map('r', M.rename_)
    map('d', M.delete_)
    map('y', function() M.copy_(false) end)
    map('x', function() M.copy_(true) end)
    map('p', M.paste_)
    map('q', M.toggle)
    map('<leader>e', M.toggle)

    render()
end

return M
