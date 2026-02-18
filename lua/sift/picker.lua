local M = {}

-- populate quickfix list from table of results
function M.quickfix(results)
	local items = {}
	for _, r in ipairs(results) do
		table.insert(items, {
			filename = r.file or "",
			lnum = r.line or 1,
			col = r.col or 1,
			text = r.message or "Vulnerability",
		})
	end
	vim.fn.setqflist({}, " ", { title = "Sift Results", items = items })
	vim.cmd("copen")
end

return M
