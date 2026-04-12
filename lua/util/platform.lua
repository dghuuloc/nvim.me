-- Central platform detection + path helpers.
-- Every other module imports this instead of calling os.getenv("HOME") directory

local M = {}

-- ── OS detection ─────────────────────────────────────────────────────────────
M.is_win   = vim.fn.has("win32")  == 1 or vim.fn.has("win64") == 1
M.is_mac   = vim.fn.has("mac")    == 1 or vim.fn.has("macunix") == 1
M.is_linux = vim.fn.has("unix")   == 1 and not M.is_mac
M.is_wsl   = M.is_linux and (
    vim.fn.filereadable("/proc/version") == 1 and
    vim.fn.readfile("/proc/version")[1]:lower():match("microsoft") ~= nil
)

-- ── Home directory ────────────────────────────────────────────────────────────
-- On Windows: C:\Users\<user>  (forward-slash form used everywhere)
M.home = M.is_win
    and (os.getenv("USERPROFILE") or "C:/Users/User"):gsub("\\","/")
    or  os.getenv("HOME") or "~"

-- ── App installation root ─────────────────────────────────────────────────────
-- Linux/Mac: ~/apps
-- Windows: ~/AppData/Local/nvim-apps
M.apps = M.is_win
    and (M.home .. "/AppData/Local/nvim-apps")
    or  (M.home .. "/apps")

-- ── Config dir ────────────────────────────────────────────────────────────────
M.config_dir = vim.fn.stdpath("config"):gsub("\\","/")
M.data_dir   = vim.fn.stdpath("data") :gsub("\\","/")
M.cache_dir  = vim.fn.stdpath("cache"):gsub("\\","/")
M.mason_dir  = vim.fn.expand("$MASON"):gsub("\\","/")

function M.join(...)
    local parts = {...}
    return table.concat(parts, "/"):gsub("//+","/")
end

-- ── Resolve a path: forward-slashes, no trailing slash ───────────────────────
function M.path(p)
    if type(p) ~= "string" then return "" end
    return p:gsub("\\","/"):gsub("/$","")
end

-- ── exe: returns executable name with .exe on Windows ────────────────────────
function M.exe(name)
    if M.is_win and not name:match("%.exe$") then return name .. ".exe" end
    return name
end

-- ── find_exe: search common locations, return first found ────────────────────
function M.find_exe(names)
    for _, n in ipairs(type(names)=="string" and {names} or names) do
        local full = vim.fn.exepath(n)
        if full ~= "" then return M.path(full) end
    end
    return nil
end

-- ── python: find best python interpreter ─────────────────────────────────────
function M.find_python()
    if M.is_win then
        local candidates = {
            M.home .. "/AppData/Local/Programs/Python/Python313/python.exe",
            M.home .. "/AppData/Local/Programs/Python/Python312/python.exe",
            M.home .. "/AppData/Local/Programs/Python/Python311/python.exe",
            M.home .. "/.venv/Scripts/python.exe",
            M.home .. "/venv/Scripts/python.exe",
        }
        for _, p in ipairs(candidates) do
            if vim.uv.fs_stat(p) then return M.path(p) end
        end
        return M.find_exe({ "python","python3"})
    else
        local candidates = {
            M.home .. "/.virtualenvs/nvim/bin/python",
            M.home .. "/.venv/bin/python",
            M.home .. "/venv/bin/python",
            M.find_exe({"python3","python"}),
        }
        for _, p in ipairs(candidates) do
            if p and p ~= "" and vim.uv.fs_stat(p) then return p end
        end
        return "python3"
    end
end

-- ── java: find JDK home ───────────────────────────────────────────────────────
function M.find_java_home()
    -- Explicit env var wins
    local java_home = os.getenv("JAVA_HOME")
    if java_home and java_home ~= "" then
        return M.path(java_home)
    end

    if M.is_win then
        local windows_java_paths = {
            "C:/Program Files/Java/jdk-1.8",
            "C:/Program Files/Java/jdk-11",
            "C:/Program Files/Java/jdk-17",
            "C:/Program Files/Java/jdk-19",
            "C:/Program Files/Java/jdk-21",
            "C:/Program Files/Java/jdk-22",
            "C:/Program Files/Java/jdk-23",
            "C:/Program Files/Java/jdk-24",
            "C:/Program Files/Java/jdk-25",
        }
        for _, p in ipairs(windows_java_paths) do
            if vim.uv.fs_stat(p) then return M.path(p) end
        end

    else
        local linux_java_paths = {
            "/usr/lib/jvm/java-21-openjdk-amd64",
            "/usr/lib/jvm/default-java",
            "/opt/homebrew/opt/openjdk@21",
            "/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home"
        }
        for _, p in ipairs(linux_java_paths) do
            if vim.uv.fs_stat(p) then return p end
        end
    end
end

-- ── node: find node.exe ───────────────────────────────────────────────────────
function M.find_node()
    local p = vim.fn.exepath("node")
    return p ~= "" and M.path(p) or nil
end

-- ── shell: preferred shell for terminal ───────────────────────────────────────
function M.shell()
    if M.is_win then
        -- Prefer PowerShell 7, fall back to pwsh, then cmd
        for _, s in ipairs({ "pwsh", "powershell", "cmd" }) do
            local p = vim.fn.exepath(s)
            if p ~= "" then return p end
        end
        return "cmd.exe"
    else
        return os.getenv("SHELL") or "bash"
    end
end

-- ── path separator ────────────────────────────────────────────────────────────
M.sep = M.is_win and "\\" or "/"

-- ── mkdir helper ─────────────────────────────────────────────────────────────
function M.mkdir(p)
    vim.fn.mkdir(p, "p")
end

return M
