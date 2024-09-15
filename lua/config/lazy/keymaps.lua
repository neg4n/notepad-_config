return {
	"folke/which-key.nvim",
	lazy = false,
	priority = 9999,
	opts = {},
	config = function()
		-- Disable 'recording feature'
		vim.keymap.set("n", "q", "<Nop>", { noremap = true })

		require("which-key").add({
			{ "gl", "$", desc = "Go to end of the line", mode = { "n", "v" } },
			{ "mm", "%", desc = "Go to the matching bracket", mode = { "n", "v" } },

			-- Leader keymaps
			{ "<leader>", group = "Leader Commands" },
			{ "<leader>p", group = "Project" },
			{ "<leader>pv", vim.cmd.Ex, desc = "Open File Explorer" },
			{ "<leader>y", [["+y]], desc = "Yank to System Clipboard", mode = { "n", "v" } },
			{ "<leader>Y", [["+Y]], desc = "Yank Line to System Clipboard" },
			{ "<leader>d", [["_d]], desc = "Delete without Yanking", mode = { "n", "v" } },
			{ "<leader>f", "<cmd>Format<CR>", desc = "Format File" },
			{ "<leader>k", "<cmd>lnext<CR>zz", desc = "Next Location List Item" },
			{ "<leader>j", "<cmd>lprev<CR>zz", desc = "Previous Location List Item" },
			{ "<leader>m", group = "Misc" },
			{ "<leader>mr", "<cmd>CellularAutomaton make_it_rain<CR>", desc = "Make It Rain" },

			-- Normal mode keymaps
			{ mode = "n" },
			{ "n", "nzzzv", desc = "Next Search Result and Center" },
			{ "N", "Nzzzv", desc = "Previous Search Result and Center" },
			{ "q", "<Nop>", desc = "Disable Q" },

			-- Scroll wheel keymaps
			{ mode = { "n", "v", "i" } },
			{ "<ScrollWheelRight>", "<Nop>", desc = "Disable Horizontal Scroll Right" },
			{ "<ScrollWheelLeft>", "<Nop>", desc = "Disable Horizontal Scroll Left" },
			{ "<S-ScrollWheelUp>", "<ScrollWheelRight>", desc = "Horizontal Scroll Right" },
			{ "<S-ScrollWheelDown>", "<ScrollWheelLeft>", desc = "Horizontal Scroll Left" },
		})
	end,
}
