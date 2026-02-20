local M = {}

M.check = function()
	vim.health.start("redline.nvim report")

	-- 1. Check for opengrep binary
	vim.health.info("Checking for 'opengrep' binary...")
	if vim.fn.executable("opengrep") == 1 then
		vim.health.ok("'opengrep' binary is installed and executable.")
	else
		-- Check the fallback path we used in scan.lua
		local fallback = os.getenv("HOME") .. "/.local/bin/opengrep"
		if vim.fn.executable(fallback) == 1 then
			vim.health.ok("'opengrep' found at fallback path: " .. fallback)
		else
			vim.health.error(
				"'opengrep' binary not found.",
				{ "Install opengrep: https://github.com/opengrep/opengrep", "Ensure it is in your $PATH" }
			)
		end
	end

	-- 2. Check for Snacks.nvim (Dependency)
	vim.health.info("Checking for Snacks.nvim dependency...")
	local has_snacks, _ = pcall(require, "snacks")
	if has_snacks then
		vim.health.ok("Snacks.nvim is installed.")
	else
		vim.health.error(
			"Snacks.nvim not found.",
			{ "This plugin requires Snacks.nvim for the results picker and notifications." }
		)
	end
end

return M

