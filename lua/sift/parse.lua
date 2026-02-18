local M = {}

--- Safely parse JSON from OpenGrep stdout and format for Snacks Picker
function M.json(stdout)
  if type(stdout) ~= "string" or stdout == "" then
    return nil
  end

  -- Find where the actual JSON starts to skip the CLI header/box
  local start_idx = stdout:find("{")
  if not start_idx then
    return nil
  end

  local json_text = stdout:sub(start_idx)
  local ok, decoded = pcall(vim.json.decode, json_text)

  if not ok or not decoded.results then
    return nil
  end

  -- We map the opengrep 'results' into a flat list for the picker
  local formatted = {}
  for _, res in ipairs(decoded.results) do
    table.insert(formatted, {
      file = res.path,
      -- Snacks looks for 'text' to show in the list
      text = (res.extra and res.extra.lines) or "Unknown match",
      -- Store original data for the previewer/jump logic
      pos = { res.start.line, res.start.col - 1 }, -- Neovim columns are 0-indexed
      check_id = res.check_id,
      severity = res.extra and res.extra.severity or "INFO",
      message = res.extra and res.extra.message or "",
    })
  end

  return formatted
end

return M