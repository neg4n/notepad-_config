return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	lazy = false,
	version = {
    commit = "f97a2d9bc17f9690681542b6858b617dfc3ed02d"
  },
	opts = {
		provider = "copilot",
		auto_suggestions_provider = "copilot",
    mappings = {
      accept = "<Tab>",
    },
		claude = {
			endpoint = "https://api.anthropic.com",
			model = "claude-3-5-sonnet-20240620",
			temperature = 0,
			max_tokens = 4096,
		},
		behaviour = {
			auto_suggestions = true,
		},
		-- add any opts here
	},
	build = "make",
	dependencies = {
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		"zbirenbaum/copilot.lua",
		{
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					use_absolute_path = true,
				},
			},
		},
		{
			-- Make sure to set this up properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
}
