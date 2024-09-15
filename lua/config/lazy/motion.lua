return {
	"smoka7/hop.nvim",
	version = "*",
	opts = {},
	config = function()
		require("hop").setup({ keys = "etovxqpdygfblzhckisuran" })
		require("which-key").add({
			{ "gw", "<CMD>:HopWord<CR>", desc = "Navigate the buffer", icon = "", mode = "n" },
		})
	end,
}
