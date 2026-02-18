local M = {}

---@param msg string
---@param level string|number "INFO"|"WARN"|"ERROR" or vim.log.levels
---@param opts table? { timeout: number|false, replace: any }
function M.notify(msg, level, opts)
    opts = opts or {}
    
    -- Map string levels to vim.log.levels
    local levels = {
        INFO = vim.log.levels.INFO,
        WARN = vim.log.levels.WARN,
        ERROR = vim.log.levels.ERROR,
    }
    
    local nvim_level = type(level) == "string" and levels[level] or level or levels.INFO

    -- Default timeout to 3000ms, but allow false for persistent
    local timeout = opts.timeout
    if timeout == nil then
        timeout = 3000
    end

    local notify_opts = {
        title = "Sift",
        timeout = timeout,
        replace = opts.replace,
    }

    -- If noice/nvim-notify is active, this returns a record/ID
    -- If not, it returns nil but still shows the message
    return vim.notify(msg, nvim_level, notify_opts)
end

return M