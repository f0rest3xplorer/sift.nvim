local M = {}

-- Wrapper for Project Scan
function M.project_scan()
	require("redline.scan").run(".", function(results)
		require("redline.display").show(results)
	end)
end

-- Wrapper for File Scan
function M.file_scan()
	local file = vim.fn.expand("%:p")
	if file == "" then
		vim.notify("RedLine: No file to scan", vim.log.levels.WARN)
		return
	end
	require("redline.scan").run(file, function(results)
		require("redline.display").show(results)
	end)
end

-- Wrapper for Resume
function M.resume_scan()
	require("redline.display").resume()
end

function M.setup()
	-- Create commands that point to our functions
	vim.api.nvim_create_user_command("RedLineProject", M.project_scan, { desc = "Scan project" })
	vim.api.nvim_create_user_command("RedLineFile", M.file_scan, { desc = "Scan current file" })
	vim.api.nvim_create_user_command("RedLineResume", M.resume_scan, { desc = "Resume last scan" })
end

return M
