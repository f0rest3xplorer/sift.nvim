local M = {}

-- Store the last results in memory
local last_results = nil

---@param results table The formatted results from parse.lua
function M.show(results)
	if not results or #results == 0 then
		vim.notify("Sift: No results to display.", vim.log.levels.WARN, { title = "Sift" })
		return
	end

	-- Save for resume functionality
	last_results = results

	M.open_picker(results)
end

-- Re-open the last results without re-scanning
function M.resume()
	if not last_results then
		vim.notify("Sift: No previous scan results found.", vim.log.levels.INFO, { title = "Sift" })
		return
	end
	M.open_picker(last_results)
end

-- Core picker logic
function M.open_picker(items)
	local severity_hl = {
		HIGH = "DiagnosticError",
		MEDIUM = "DiagnosticWarn",
		LOW = "DiagnosticInfo",
		INFO = "DiagnosticHint",
	}

	-- Helper function to convert table or string to a readable string
	local function to_str(val, fallback)
		if not val then
			return fallback or "N/A"
		end
		if type(val) == "table" then
			return table.concat(val, ", ")
		end
		return tostring(val)
	end

	Snacks.picker.pick({
		title = "Sift Results",
		items = items,
		layout = {
			preset = "vertical",
			cycle = true,
		},
		-- Formatting the list view
		format = function(item, _)
			local hl = severity_hl[item.severity] or "DiagnosticInfo"
			return {
				{ item.severity:sub(1, 1) .. " ", hl },
				{ item.file .. ":" .. item.pos[1], "line_no" },
				{ " " .. (item.message or ""), "comment" },
			}
		end,
		-- Detailed preview showing the Opengrep message
		preview = function(ctx)
			local item = ctx.item
			local lines = {
				"# " .. (item.check_id or "Unknown Check"),
				"",
				"Severity:   " .. (item.severity or "Unknown"),
				"Category:   " .. to_str(item.category),
				"",
				"Message:    " .. (item.message or "No Message"),
				"",
				"Likelihood: " .. to_str(item.likelyhood),
				"Impact:     " .. to_str(item.impact),
				"Confidence: " .. to_str(item.confidence),
				"",
				"CWE:        " .. to_str(item.cwe),
				"OWASP:      " .. to_str(item.owasp),
				"Subcat:     " .. to_str(item.subcategory),
				"Tech:       " .. to_str(item.technology),
				"Class:      " .. to_str(item.vuln_class),
				"",
				"Source:     " .. to_str(item.source),
				"File:       " .. item.file,
				"Line:       " .. item.pos[1],
				"Col:        " .. (item.pos[2] + 1), -- Showing 1-indexed column for users
			}
			return ctx.preview:set_lines(lines)
		end,
		-- Jump to file on confirm
		confirm = function(picker, item)
			picker:close()
			if item then
				local buf = vim.fn.bufadd(item.file)
				vim.api.nvim_win_set_buf(0, buf)
				-- Set cursor (Line is 1-indexed, Col is 0-indexed)
				vim.api.nvim_win_set_cursor(0, { item.pos[1], item.pos[2] })
			end
		end,
		-- Custom keymaps inside the picker
		win = {
			input = {
				keys = {
					["<C-h>"] = { "filter_high", mode = { "n", "i" } },
					["<C-m>"] = { "filter_medium", mode = { "n", "i" } },
					["<C-l>"] = { "filter_low", mode = { "n", "i" } },
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

