local M = {}
local snacks = require("snacks")

-- State variables (local to this module)
local timer = nil
local start_time = 0
local idx = 1
local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

--[[Helper to count severities
local function summarize(results)
	local counts = { CRITICAL = 0, HIGH = 0, MEDIUM = 0, LOW = 0 }
	for _, res in ipairs(results) do
		local sev = res.severity or "LOW"
		if counts[sev] ~= nil then
			counts[sev] = counts[sev] + 1
		end
	end
	return counts
end
--]]
--

local function summarize(data)
	-- 1. Ensure we are looking at the array of matches
	local matches = data.results or data
	local counts = { CRITICAL = 0, HIGH = 0, MEDIUM = 0, LOW = 0 }
	-- Add this mapping inside summarize to bridge the gap
	local map = {
		ERROR = "CRITICAL",
		WARNING = "HIGH",
		INFO = "LOW",
	}

	-- Inside the loop
	if type(matches) ~= "table" then
		return counts
	end

	for _, res in ipairs(matches) do
		-- 2. Opengrep severity is usually inside 'extra'
		local sev = (res.extra and res.extra.severity) or res.severity or "LOW"
		sev = sev:upper()
		sev = map[sev] or sev -- Convert ERROR to CRITICAL, etc.
		if counts[sev] ~= nil then
			counts[sev] = counts[sev] + 1
		end
	end
	return counts
end

function M.start()
	idx = 1
	start_time = vim.loop.hrtime()

	-- Stop any existing timer if user starts a new scan while one is running
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end

	snacks.notify("Scanning... " .. spinner_frames[idx], {
		title = "Redline",
		timeout = false,
		id = "redline_scan",
	})

	timer = vim.loop.new_timer()
	timer:start(
		100,
		100,
		vim.schedule_wrap(function()
			idx = (idx % #spinner_frames) + 1
			snacks.notify("Scanning... " .. spinner_frames[idx], {
				title = "Redline",
				timeout = false,
				id = "redline_scan",
			})
		end)
	)
end

function M.stop(results)
	if timer then
		timer:stop()
		timer:close()
		timer = nil
	end

	local elapsed_ms = (vim.loop.hrtime() - start_time) / 1e6
	local elapsed = string.format("%.2fs", elapsed_ms / 1000)

	-- Extract the array correctly
	local matches = results.results or results or {}
	local total = #matches
	local counts = summarize(results)

	local message
	if total == 0 then
		message = "No issues found (" .. elapsed .. ")"
	else
		message = string.format(
			"%d issues (%s)\nC:%d H:%d M:%d L:%d",
			total,
			elapsed,
			counts.CRITICAL,
			counts.HIGH,
			counts.MEDIUM,
			counts.LOW
		)
	end

	snacks.notify(message, {
		title = "Redline",
		id = "redline_scan",
		level = vim.log.levels.INFO,
		timeout = 5000,
	})
end

return M
