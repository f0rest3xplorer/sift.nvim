return {
	{
		name = "sift",
		cmd = { "SiftProject", "SiftFile" },

		config = function()
			local scan = require("sift.scan")
			local parse = require("sift.parse")
			local picker = require("sift.picker")

			vim.api.nvim_create_user_command("SiftProject", function()
				scan.run(".", function(stdout)
					local results = parse.json(stdout)
					if results then
						picker.quickfix(results)
					end
				end)
			end, { desc = "Scan current project" })

			vim.api.nvim_create_user_command("SiftFile", function()
				local file = vim.fn.expand("%:p")
				scan.run(file, function(stdout)
					local results = parse.json(stdout)
					if results then
						picker.quickfix(results)
					end
				end)
			end, { desc = "Scan current file" })
		end,
	},
}
