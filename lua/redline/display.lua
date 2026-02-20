local M = {}

-- Store the last results in memory for the resume functionality
local last_results = nil

---@param results table The formatted results from parse.lua
function M.show(results)
	if not results or #results == 0 then
		vim.notify("RedLine: No results to display.", vim.log.levels.WARN, { title = "RedLine" })
		return
	end

	last_results = results
	M.open_picker(results)
end

-- Re-open the last results without re-scanning
function M.resume()
	if not last_results then
		vim.notify("RedLine: No previous scan results found.", vim.log.levels.INFO, { title = "RedLine" })
		return
	end
	M.open_picker(last_results)
end

-- Core picker logic
function M.open_picker(items)
	local severity_hl = {
		CRITICAL = "DiagnosticError",
		HIGH = "DiagnosticError",
		ERROR = "DiagnosticError",
		MEDIUM = "DiagnosticWarn",
		WARNING = "DiagnosticWarn",
		LOW = "DiagnosticInfo",
		INFO = "DiagnosticHint",
	}

	local severity_map = {
		ERROR = "HIGH",
		WARNING = "MEDIUM",
		INFO = "LOW",
	}

	local severity_weight = {
		CRITICAL = 10,
		HIGH = 8,
		MEDIUM = 5,
		LOW = 2,
		INFO = 1,
	}

	-- 1. Calculate Summary Stats & Prepare Items for Sorting
	local stats = { CRITICAL = 0, HIGH = 0, MEDIUM = 0, LOW = 0, INFO = 0 }
	for _, item in ipairs(items) do
		-- Normalize severity names
		item.severity = severity_map[item.severity] or item.severity
		-- Inject numerical weights for the sorter
		item.severity_weight = severity_weight[item.severity] or 0
		-- Ensure picker uses the start line for sorting within files
		item.line = item.pos[1]

		if stats[item.severity] ~= nil then
			stats[item.severity] = stats[item.severity] + 1
		end
	end

	-- 2. Build Dynamic Title Summary
	local title_parts = {}
	if stats.CRITICAL > 0 then
		table.insert(title_parts, stats.CRITICAL .. " Critical")
	end
	if stats.HIGH > 0 then
		table.insert(title_parts, stats.HIGH .. " High")
	end
	if stats.MEDIUM > 0 then
		table.insert(title_parts, stats.MEDIUM .. " Medium")
	end

	local summary = #title_parts > 0 and (" (" .. table.concat(title_parts, ", ") .. ")") or ""
	local full_title = "RedLine Results" .. summary

	-- Helper to safely convert values to strings
	local function to_str(value)
		if value == nil then
			return "N/A"
		end
		if type(value) == "table" then
			return table.concat(value, ", ")
		end
		return tostring(value)
	end

	-- 3. Launch Snacks Picker
	require("snacks").picker.pick({
		title = full_title,
		items = items,
		-- Force sorting by severity weight (descending) so bad stuff is at the top
		sort = {
			fields = { "severity_weight:desc", "file:asc", "line:asc" },
		},
		matcher = {
			sort_empty = true, -- Crucial: maintains severity order even without a search query
		},
		layout = {
			layout = {
				box = "horizontal",
				width = 0.95,
				height = 0.85,
				border = "rounded",
				{
					box = "vertical",
					width = 0.35,
					{ win = "list", border = "rounded" },
				},
				{
					win = "preview",
					width = 0.65,
					border = "rounded",
					title = " Finding Details ",
					title_pos = "center",
					wo = { wrap = true },
					render = "markdown",
				},
			},
		},
		-- List view formatting
		format = function(item, _)
			local hl = severity_hl[item.severity] or "DiagnosticInfo"
			return {
				{ string.format("%-8s", item.severity) .. " ", hl },
				{ "(" .. to_str(item.vuln_class) .. ") ", "Special" },
				{ item.filename .. ":" .. item.pos[1], "line_no" },
				{ " " .. (item.message or ""), "comment" },
			}
		end,

		-- Markdown Preview logic
		preview = function(ctx)
			local item = ctx.item
			if not item then
				return
			end

			local code_lines = {}
			if item.file and item.pos then
				local start_line = math.max(1, item.pos[1] - 2)
				local end_line = item.pos[1] + 2
				-- Faster Neovim-native file reading
				local file_content = vim.fn.readfile(item.file)
				for i = start_line, math.min(end_line, #file_content) do
					table.insert(code_lines, file_content[i])
				end
			end

			local callout_severity = {
				CRITICAL = "CAUTION",
				HIGH = "CAUTION",
				MEDIUM = "WARNING",
				LOW = "IMPORTANT",
				INFO = "NOTE",
			}

			local callout_type = callout_severity[item.severity] or "NOTE"
			local ft = vim.filetype.match({ filename = item.file }) or ""

			local lines = {
				"",
				"> [!" .. callout_type .. "] " .. item.severity,
				">",
				"> Likelihood: **" .. to_str(item.likelihood) .. "** | Impact: **" .. to_str(item.impact) .. "**",
				"> Confidence: **" .. to_str(item.confidence) .. "**",
				"",
				"## Description",
				"",
				(item.message or "No description provided."),
				"",
				"## Location",
				"",
				item.file .. " Row:" .. item.pos[1] .. " Col:" .. (item.pos[2] + 1),
				"",
				"",
				"**Code Preview:**",
				"",
				"```" .. ft,
			}

			for _, line in ipairs(code_lines) do
				table.insert(lines, line)
			end
			table.insert(lines, "```")

			local rest = {
				"",
				"## Classification",
				"",
				"- **CWE:** " .. to_str(item.cwe),
				"- **OWASP:** " .. to_str(item.owasp),
				"",
				"## References",
				"",
				(to_str(item.references) ~= "N/A" and to_str(item.references) or "No references available."),
			}

			for _, line in ipairs(rest) do
				table.insert(lines, line)
			end

			ctx.preview:set_lines(lines)
			ctx.preview:highlight({ ft = "markdown" })
		end,

		-- Jump to code on Enter
		confirm = function(picker, item)
			picker:close()
			if item and item.file then
				vim.schedule(function()
					vim.cmd("edit " .. vim.fn.fnameescape(item.file))
					vim.api.nvim_win_set_cursor(0, { item.pos[1], item.pos[2] })
				end)
			end
		end,
	})
end

return M
