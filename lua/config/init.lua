require("config.set-vim-options")
require("config.install-plugin-manager")
require("config.auto-commands")

function R(name)
	require("plenary.reload").reload_module(name)
end

vim.filetype.add({
	extension = {
		templ = "templ",
	},
})
