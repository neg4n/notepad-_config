return {
	"ibhagwan/fzf-lua",
	dependencies = {
		{ "junegunn/fzf", build = "./install --bin" },
		"BurntSushi/ripgrep",
		"sharkdp/fd",
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("fzf-lua").setup({
			"max-perf",
			fzf_colors = true,
			previewers = {
				bat = {
					cmd = "bat",
					args = "--color=always --style=changes",
				},
			},
			winopts = {
				height = 0.55,
				width = 1,
				row = 1,
				col = 0,
				backdrop = 50,
				border = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
				preview = {
					border = "border-top",
					vertical = "down:45%",
					horizontal = "right:60%",
					winopts = {
						preview = "none",
						cursorline = false,
						number = false,
					},
				},
			},
		})

		_G.live_ripgrep = function(opts)
			opts = opts or {}
			opts.prompt = "rg> "
			opts.file_icons = true
			opts.color_icons = true
			-- setup default actions for edit, quickfix, etc
			opts.actions = FzfLua.defaults.actions.files
			-- see preview overview for more info on previewers
			opts.previewer = "builtin"
			opts.fn_transform = function(x)
				return FzfLua.make_entry.file(x, opts)
			end
			return FzfLua.fzf_live(function(args)
				return "rg --column --color=always -- " .. vim.fn.shellescape(args[1] or "")
			end, opts)
		end

		local fzf = require("fzf-lua")

		vim.keymap.set("n", "<leader>f", fzf.files, { desc = "Find files" })
		vim.keymap.set("n", "<leader>b", fzf.buffers, { desc = "Navigate through open buffers" })
		vim.keymap.set("n", "<leader>/", _G.live_ripgrep, { desc = "Live grep" })
		vim.keymap.set("n", "<leader>g", fzf.git_diff, { desc = "Git files" })
		vim.keymap.set("n", "<leader>vh", fzf.help_tags, { desc = "Help tags" })
	end,
}
