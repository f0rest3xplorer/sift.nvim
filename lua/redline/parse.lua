local M = {}

--- Safely parse JSON from OpenGrep stdout and format for Snacks Picker
function M.json(stdout)
	if type(stdout) ~= "string" or stdout == "" then
		return nil
	end

	-- Find where the actual JSON starts to skip the CLI header/box
	local start_idx = stdout:find("{")
	if not start_idx then
		return nil
	end

	local json_text = stdout:sub(start_idx)
	local ok, decoded = pcall(vim.json.decode, json_text)

	if not ok or not decoded.results then
		return nil
	end

	-- We map the opengrep 'results' into a flat list for the picker
	local formatted = {}
	for _, res in ipairs(decoded.results) do
		table.insert(formatted, {
			file = res.path,
			filename = res.path:match("([^/\\]+)$"),
			message = res.extra.message or "",
			likelihood = res.extra.metadata.likelihood,
			impact = res.extra.metadata.impact,
			confidence = res.extra.metadata.confidence,
			category = res.extra.metadata.category,
			cwe = res.extra.metadata.cwe,
			owasp = res.extra.metadata.owasp,
			references = res.extra.metadata.references,
			subcategory = res.extra.metadata.subcategory,
			technology = res.extra.metadata.technology,
			vuln_class = res.extra.metadata.vulnerability_class,
			source = res.extra.metadata.source,
			-- Store original data for the previewer/jump logic
			pos = { res.start.line, res.start.col - 1 }, -- Neovim columns are 0-indexed
			check_id = res.check_id,
			severity = res.extra and res.extra.severity or "INFO",
			lines = res.extra.metadata.lines,
		})
	end

	return formatted
end

return M
