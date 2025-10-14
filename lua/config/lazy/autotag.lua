return {
	"windwp/nvim-ts-autotag",
  event = {"BufReadPre", "BufNewFile"},
  depdendencies = {"nvim-treesitter/nvim-treesitter"},
	-- config = function()
	--	require("nvim-ts-autotag").setup({
	--		opts = {
	--			enable_close = true,
	--			enable_rename = true,
	--			enable_close_on_slash = false
	--		},
	--		filetypes = {
	--			'html', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'svelte', 'vue', 'tsx', 'jsx', 'rescript',
	--			'xml', 'php', 'markdown', 'astro', 'glimmer', 'handlebars', 'hbs'
	--		},
	--	})
	-- end,
}
