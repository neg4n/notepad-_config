vim.api.nvim_create_augroup("main", {})
vim.api.nvim_create_augroup("formatlint", {})
vim.api.nvim_create_augroup("HighlightYank", {})

vim.api.nvim_create_autocmd("TextYankPost", {

	group = "HighlightYank",
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 40,
		})
	end,
})



vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = "main",
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

vim.api.nvim_create_autocmd({ "BufWritePost" }, {
	group = "formatlint",
	command = ":FormatWrite",
})
