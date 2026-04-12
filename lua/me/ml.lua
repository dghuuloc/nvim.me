-- lua/me/ml_mode.lua
-- Switch between normal Python DAP and mlbuddy model-inspection mode.

local M = {
    mode = "code",
}

local function notify(msg)
    vim.notify(msg, vim.log.levels.INFO, { title = "ml" })
end

local function get_cfg()
    local ok, mlbuddy = pcall(require, "mlbuddy")
    if not ok or not mlbuddy._cfg then
        return nil
    end
    return mlbuddy._cfg
end

function M.apply(mode)
    local cfg = get_cfg()
    if not cfg then
        vim.notify("mlbuddy is not available", vim.log.levels.WARN, { title = "ml" })
        return
    end

    local ok_guard, guard = pcall(require, "mlbuddy.guard")
    if not ok_guard then
        vim.notify("mlbuddy.guard is not available", vim.log.levels.WARN, { title = "ml" })
        return
    end

    guard.remove_dap_listener("mlbuddy_debugger")
    guard.remove_dap_listener("mlbuddy_dataloader")

    if mode == "mode" then
        cfg.debugger.enabled = true
        cfg.debugger.auto_inspect = true
        cfg.debugger.virt_text = true
        cfg.dataloader.auto_inspect = false

        local ok_dbg, dbg = pcall(require, "mlbuddy.debugger")
        if ok_dbg then
            dbg.setup_dap(cfg)
        end

        M.mode = "model"
        notify("Model mode enabled")
        return

    end

    cfg.debugger.auto_inspect   = false
    cfg.debugger.virt_text      = false
    cfg.dataloader.auto_inspect = false

    M.mode = "code"
    -- notify("Normal Python DAP mode enabled")
end

function M.toggle()
    if M.mode == "code" then
        M.apply("model")
    else
        M.apply("code")
    end
end

function M.current()
    return M.mode
end

return M
