local parse = require("redline.parse")

local M = {}

function M.run(target, callback)
	-- 1. Check if the binary exists in the user's PATH
	-- This makes it work for anyone who has installed opengrep globally
	local cmd = "opengrep"

	if vim.fn.executable(cmd) ~= 1 then
		-- Optional: Check common local install paths as a fallback
		local home = os.getenv("HOME")
		local fallback = home .. "/.local/bin/opengrep"

		if vim.fn.executable(fallback) == 1 then
			cmd = fallback
		else
			-- If we still can't find it, tell the user exactly what's wrong
			vim.notify(
				"RedLine: 'opengrep' binary not found in PATH.\n" .. "Please install it or ensure it is in your $PATH.",
				vim.log.levels.ERROR,
				{ title = "RedLine" }
			)
			return
		end
	end

	local notify_id = vim.notify("RedLine: Initializing...", vim.log.levels.INFO, {
		title = "RedLine",
	})

	local function update_progress(msg, level, timeout)
		notify_id = vim.notify(msg, level or vim.log.levels.INFO, {
			replace = notify_id,
			title = "RedLine",
			timeout = timeout,
		})
	end

	update_progress("Scanning the code with opengrep to find vulnerabilities...")

	-- 2. Use the 'cmd' variable we validated above
	vim.system({
		cmd,
		"scan",
		"--json",
		"--quiet",
		target,
	}, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				update_progress("Scan failed", vim.log.levels.ERROR, 5000)
				return
			end

			update_progress("Parsing results...")
			local parsed = parse.json(result.stdout)

			if not parsed or #parsed == 0 then
				update_progress("No issues found!", vim.log.levels.INFO, 3000)
				return
			end

			update_progress("Opening " .. #parsed .. " results...", vim.log.levels.INFO, 1)

			if callback then
				callback(parsed)
			end
		end)
	end)
end

return M
