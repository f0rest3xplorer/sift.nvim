-- Prevent the plugin from loading twice
if vim.g.loaded_sift == 1 then
  return
end
vim.g.loaded_sift = 1

-- Create the user commands
-- We use a pcall or a check to ensure the lua modules exist
-- Note: We 'require' inside the function so it only loads the code when called (Lazy)

vim.api.nvim_create_user_command("SiftProject", function(opts)
  local scan = require("sift.scan")
  local display = require("sift.display")
  
  local target = (opts.args ~= "") and opts.args or "."
  scan.run(target, function(results)
    display.show(results)
  end)
end, {
  nargs = "?",
  complete = "dir",
  desc = "Sift: Scan entire project",
})

vim.api.nvim_create_user_command("SiftFile", function()
  local scan = require("sift.scan")
  local display = require("sift.display")
  
  local target = vim.api.nvim_buf_get_name(0)
  if target == "" then
    -- Using vim.notify is cleaner than print for LazyVim users
    vim.notify("Sift: No file to scan!", vim.log.levels.WARN)
        local notify_opts = {
            title = "Sift", -- This makes every popup labeled
            timeout = timeout,
            replace = opts.replace,
        }
    return
  end

  scan.run(target, function(results)
    display.show(results)
  end)
end, {
  nargs = 0,
  desc = "Sift: Scan current file",

vim.api.nvim_create_user_command("SiftResume", function()
    require("sift.display").resume()
end, { desc = "Sift: Reopen last scan results" })
})