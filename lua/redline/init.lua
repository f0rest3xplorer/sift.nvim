local M = {}

-- Helper to get notify safely
local function get_notify()
	return require("redline.notify")
end

function M.project_scan()
	get_notify().start()
	require("redline.scan").run(".", function(results)
		get_notify().stop(results)
		require("redline.display").show(results)
	end)
end

function M.file_scan()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("RedLine: No file to scan", vim.log.levels.WARN)
		return
	end

	get_notify().start()
	require("redline.scan").run(file, function(results)
		get_notify().stop(results)
		require("redline.display").show(results)
	end)
end

function M.resume_scan()
	require("redline.display").resume()
end

function M.setup()
	-- Using anonymous functions here ensures the module is
	-- re-required only when the command is actually run.
	vim.api.nvim_create_user_command("RedLineProject", function()
		M.project_scan()
	end, { desc = "Scan project" })

	vim.api.nvim_create_user_command("RedLineFile", function()
		M.file_scan()
	end, { desc = "Scan current file" })

	vim.api.nvim_create_user_command("RedLineResume", function()
		M.resume_scan()
	end, { desc = "Resume last scan" })
end

return M
