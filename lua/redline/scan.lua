local parse = require("redline.parse")

local M = {}

function M.run(target, callback)
	local cmd = "opengrep"

	if vim.fn.executable(cmd) ~= 1 then
		local home = os.getenv("HOME")
		local fallback = home .. "/.local/bin/opengrep"

		if vim.fn.executable(fallback) == 1 then
			cmd = fallback
		else
			vim.notify(
				"RedLine: 'opengrep' binary not found in PATH.\nPlease install it or ensure it is in your $PATH.",
				vim.log.levels.ERROR,
				{ title = "RedLine" }
			)

			if callback then
				callback({})
			end
			return
		end
	end

	vim.system({
		cmd,
		"scan",
		"--json",
		"--quiet",
		target,
	}, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				if callback then
					callback({})
				end
				return
			end

			local parsed = parse.json(result.stdout) or {}

			if callback then
				callback(parsed)
			end
		end)
	end)
end

return M
