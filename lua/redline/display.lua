local M = {}

-- Store the last results in memory
local last_results = nil

---@param results table The formatted results from parse.lua
function M.show(results)
	if not results or #results == 0 then
		vim.notify("RedLine: No results to display.", vim.log.levels.WARN, { title = "RedLine" })
		return
	end

	-- Save for resume functionality
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

	for _, item in ipairs(items) do
		item.severity = severity_map[item.severity] or item.severity
	end

	-- Helper function to convert table or string to a readable string
	local function to_str(value)
		if value == nil then
			return "N/A"
		end
		if type(value) == "table" then
			return table.concat(value, ", ")
		end
		return tostring(value)
	end

	Snacks.picker.pick({
		title = "RedLine Results",
		items = items,
		layout = {
			layout = {
				box = "horizontal",
				width = 0.95,
				height = 0.85,
				border = "rounded",
				{
					box = "vertical",
					width = 0.35,
					wo = {
						wrap = true,
					},
					{ win = "list", border = "rounded" },
				},
				{
					win = "preview",
					width = 0.65,
					border = "rounded",
					title = " Finding Details ",
					title_pos = "center",
					wo = {
						wrap = true,
					},
					render = "markdown",
				},
			},
		},
		-- Formatting the list view
		format = function(item, _)
			local hl = severity_hl[item.severity] or "DiagnosticInfo"
			return {
				{ item.severity .. " ", hl },
				{ "(" .. to_str(item.vuln_class) .. ") " },
				{ item.filename .. ":" .. item.pos[1], "line_no" },
				{ " " .. (item.message or ""), "comment" },
			}
		end,
		-- Detailed preview showing the Opengrep message

		preview = function(ctx)
			local item = ctx.item
			if not item then
				return
			end

			local function field(label, value)
				if not value or value == "" then
					return ""
				end
				return "- **" .. label .. ":** " .. value
			end

			-- Read the relevant lines from the file for the code snippet
			local code_lines = {}
			if item.file and item.pos then
				local start_line = math.max(1, item.pos[1] - 2) -- 2 lines of context before
				local end_line = item.pos[1] + 2 -- 2 lines of context after
				local file = io.open(item.file, "r")
				if file then
					local current = 0
					for line in file:lines() do
						current = current + 1
						if current >= start_line and current <= end_line then
							table.insert(code_lines, line)
						end
						if current > end_line then
							break
						end
					end
					file:close()
				end
			end

			local callout_severity = {
				CRITICAL = "CAUTION",
				HIGH = "CAUTION",
				ERROR = "CAUTION",
				MEDIUM = "WARNING",
				WARNING = "WARNING",
				LOW = "IMPORTANT",
				INFO = "IMPORTANT",
			}

			local callout_type = callout_severity[item.severity]
			-- Detect filetype for the fenced code block language tag
			local ft = vim.filetype.match({ filename = item.file }) or ""

			local lines = {
				"",
				"> [!" .. to_str(callout_type) .. "] ",
				">",
				"> Severity: **" .. to_str(item.severity) .. "**",
				"> Likelihood: **" .. to_str(item.likelihood) .. "**",
				"> Impact: **" .. to_str(item.impact) .. "**",
				"> Confidence: **" .. to_str(item.confidence) .. "**",
				"",
				"## Description",
				"",
				(item.message or "No description."),
				"",
				"## Location",
				"",
				"```",
				to_str(item.file) .. ": " .. "line:" .. item.pos[1] .. " col:" .. (item.pos[2] + 1),
				"```",
				"",
				"Code Preview:",
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
				field("CWE", to_str(item.cwe)),
				field("OWASP", to_str(item.owasp)),
				"",
				"## References",
				"",
				(to_str(item.references) or "No references"),
			}

			for _, line in ipairs(rest) do
				table.insert(lines, line)
			end

			-- Filter out any blank entries from optional fields that were empty
			local filtered = {}
			for i, line in ipairs(lines) do
				-- Drop list items that had no value (field() returned "")
				-- but keep intentional blank lines for spacing
				if line ~= "" or (lines[i - 1] ~= "" and lines[i - 1] ~= nil) then
					table.insert(filtered, line)
				end
			end

			ctx.preview:set_lines(filtered)
			ctx.preview:highlight({ ft = "markdown" })
		end,

		confirm = function(picker, item)
			picker:close()

			if not item or not item.file then
				return
			end

			vim.schedule(function()
				vim.cmd("edit " .. vim.fn.fnameescape(item.file))

				if item.pos then
					vim.api.nvim_win_set_cursor(0, {
						item.pos[1] or 1,
						item.pos[2] or 0,
					})
				end
			end)
		end,

		-- Custom keymaps inside the picker
		win = {
			input = {
				keys = {
					["<A-c>"] = { "filter_critical", mode = { "n", "i" } },
					["<A-h>"] = { "filter_high", mode = { "n", "i" } },
					["<A-m>"] = { "filter_medium", mode = { "n", "i" } },
					["<A-l>"] = { "filter_low", mode = { "n", "i" } },
					["<A-e>"] = { "filter_error", mode = { "n", "i" } },
				},
			},
		},
		-- Define the filtering actions
		actions = {
			filter_high = function(picker)
				picker:set_filter("HIGH")
			end,
			filter_medium = function(picker)
				picker:set_filter("MEDIUM")
			end,
			filter_low = function(picker)
				picker:set_filter("LOW")
			end,
		},
	})
end

return M
