return {
	{
		"folke/trouble.nvim",
		opts = {},
		config = function()
			local trouble = require("trouble")

			vim.keymap.set("n", "<leader>tt", function()
				trouble.toggle("diagnostics")
			end, { desc = "Toggle Trouble" })

			vim.keymap.set("n", "[t", function()
				trouble.next({ skip_groups = true, jump = true })
			end, { desc = "Next Trouble" })

			vim.keymap.set("n", "]t", function()
				trouble.previous({ skip_groups = true, jump = true })
			end, { desc = "Previous Trouble" })
		end,
	},
}
