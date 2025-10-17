return {
	"nvim-treesitter/nvim-treesitter",
  branch = "master",
  lazy = false,
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
				"tsx",
				"vue",
				"svelte",
				"typescript",
				"lua",
				"bash",
				"xml",
				"html",
				"markdown",
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
	end,
}
