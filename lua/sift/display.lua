local M = {}

-- Store the last results in memory
local last_results = nil

---@param results table The formatted results from parse.lua
function M.show(results)
  if not results or #results == 0 then
    vim.notify("Sift: No results to display.", vim.log.levels.WARN, { title = "Sift" })
    return
  end

  -- Save for resume functionality
  last_results = results

  M.open_picker(results)
end

-- Re-open the last results without re-scanning
function M.resume()
  if not last_results then
    vim.notify("Sift: No previous scan results found.", vim.log.levels.INFO, { title = "Sift" })
    return
  end
  M.open_picker(last_results)
end

-- Core picker logic
function M.open_picker(items)
  local severity_hl = {
    ERROR = "DiagnosticError",
    WARNING = "DiagnosticWarn",
    INFO = "DiagnosticInfo",
  }

  Snacks.picker.pick({
    title = "Sift Results",
    items = items,
    layout = {
      preset = "vertical",
      cycle = true,
    },
    -- Formatting the list view
    format = function(item, _)
      local hl = severity_hl[item.severity] or "DiagnosticInfo"
      return {
        { item.severity:sub(1, 1) .. " ", hl },
        { item.file .. ":" .. item.pos[1], "line_no" },
        { " " .. item.text, "comment" },
      }
    end,
    -- Detailed preview showing the Opengrep message
    preview = function(ctx)
      local item = ctx.item
      local lines = {
        "# " .. item.check_id,
        "",
        "Severity: " .. item.severity,
        "",
        item.message,
        "",
        "---",
        "File: " .. item.file,
        "Line: " .. item.pos[1],
        "Col:  " .. item.pos[2],
      }
      return ctx.preview:set_lines(lines)
    end,
    -- Jump to file on confirm
    confirm = function(picker, item)
      picker:close()
      if item then
        local buf = vim.fn.bufadd(item.file)
        vim.api.nvim_win_set_buf(0, buf)
        -- Set cursor (Line is 1-indexed, Col is 0-indexed)
        vim.api.nvim_win_set_cursor(0, { item.pos[1], item.pos[2] })
      end
    end,
    -- Custom keymaps inside the picker
    win = {
      input = {
        keys = {
          -- Pressing Ctrl-e will filter for Errors only
          ["<C-e>"] = { "filter_error", mode = { "n", "i" } },
          -- Pressing Ctrl-w will filter for Warnings only
          ["<C-w>"] = { "filter_warn", mode = { "n", "i" } },
        },
      },
    },
    -- Define the filtering actions
    actions = {
      filter_error = function(picker)
        picker:set_filter("ERROR")
      end,
      filter_warn = function(picker)
        picker:set_filter("WARNING")
      end,
    },
  })
end

return M