return {
	{
		"folke/trouble.nvim",
    opts = {},
		config = function()
			require("which-key").add({
				{
					"<leader>tt",
					function()
						require("trouble").toggle("diagnostics")
					end,
					desc = "Toggle Trouble",
					mode = "n",
				},
				{
					"[t",
					function()
						require("trouble").next({ skip_groups = true, jump = true })
					end,
					desc = "Next Trouble",
					mode = "n",
				},
				{
					"]t",
					function()
						require("trouble").previous({ skip_groups = true, jump = true })
					end,
					desc = "Previous Trouble",
					mode = "n",
				},
			}, {
				mode = "n",
			})
		end,
	},
}
