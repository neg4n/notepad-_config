return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.5",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"BurntSushi/ripgrep",
		"FeiyouG/commander.nvim",
	},
	config = function()
		require("telescope").setup({
			defaults = {
				mappings = {
					i = {
						["<esc>"] = require("telescope.actions").close,
					},
				},
			},
		})

		require("commander").setup({})
		require("commander").add({
			{
				cmd = "RelativePath",
				desc = "Copy current opened buffer's relative path",
				func = function()
					vim.fn.setreg("+", vim.fn.expand("%"))
				end,
			},
			{
				cmd = "ClipboardCopy",
				desc = "Copy selected text to clipboard",
				func = function(opts)
					local mode = opts.range > 0 and "v" or "n"
					vim.api.nvim_command(string.format("%s'<,'>yank +", mode == "v" and "'<,'>" or ""))
				end,
				range = true,
			},
			{
				cmd = "AbsolutePath",
				desc = "Copy current opened buffer's absolute path",
				func = function()
					vim.fn.setreg("+", vim.fn.expand("%:p"))
				end,
			},
			{
				cmd = "W",
				desc = "Write",
				func = function()
					vim.cmd("w")
				end,
			},
			{
				cmd = "Wq",
				desc = "Write quit",
				func = function()
					vim.cmd("wq")
				end,
			},
			{
				cmd = "Wqa",
				desc = "Write quit all",
				func = function()
					vim.cmd("wqa")
				end,
			},
			{
				cmd = "Q",
				desc = "Quit",
				func = function()
					vim.cmd("q")
				end,
			},
			{
				cmd = "Qa",
				desc = "Quit all",
				func = function()
					vim.cmd("qa")
				end,
			},
		})

		require("which-key").add({
			{
				"<leader>ff",
				function()
					require("telescope.builtin").find_files()
				end,
				desc = "Find files",
			},
			{
				"<leader>/",
				function()
					require("telescope.builtin").live_grep()
				end,
				desc = "Live grep",
			},
			{
				"<leader>g",
				function()
					require("telescope.builtin").git_files()
				end,
				desc = "Git files",
			},
			{
				"<leader>vh",
				function()
					require("telescope.builtin").help_tags()
				end,
				desc = "Help tags",
			},
		})
	end,
}
