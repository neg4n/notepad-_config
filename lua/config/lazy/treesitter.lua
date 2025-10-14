return {
	"nvim-treesitter/nvim-treesitter",
  branch = "main",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter.configs").setup({
			ensure_installed = {
				"vimdoc",
        "astro",
				"javascript",
        "cpp",
        "cmake",
        "css",
				"typescript",
				"lua",
				"bash",
				"html",
				"scss",
			},
			sync_install = false,
			auto_install = false,

			indent = {
				enable = true,
			},
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = { "markdown" },
			},
		})

		local treesitter_parser_config = require("nvim-treesitter.parsers").get_parser_configs()
		treesitter_parser_config.templ = {
			install_info = {
				url = "https://github.com/vrischmann/tree-sitter-templ.git",
				files = { "src/parser.c", "src/scanner.c" },
				branch = "master",
			},
		}

		vim.treesitter.language.register("templ", "templ")
	end,
}
