return {
	"neovim/nvim-lspconfig",
	dependencies = {
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"hrsh7th/cmp-cmdline",
		"L3MON4D3/LuaSnip",
		"hrsh7th/nvim-cmp",
		"j-hui/fidget.nvim",
		"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
	},

	config = function()
		require("lsp_lines").setup()
		local cmp = require("cmp")
		local cmp_lsp = require("cmp_nvim_lsp")

		local capabilities = vim.tbl_deep_extend(
			"force",
			{},
			vim.lsp.protocol.make_client_capabilities(),
			cmp_lsp.default_capabilities()
		)

		require("fidget").setup({})
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"ts_ls",
				"tailwindcss",
				"eslint",
				"cssls",
				"html",
			},
			handlers = {
				function(server_name)
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
					})
				end,

				["lua_ls"] = function()
					local lspconfig = require("lspconfig")
					lspconfig.lua_ls.setup({
						capabilities = capabilities,
						settings = {
							Lua = {
								diagnostics = {
									globals = { "vim", "it", "describe", "before_each", "after_each" },
								},
							},
						},
					})
				end,
			},
		})

		cmp.setup({
			snippet = {
				expand = function(args)
					require("luasnip").lsp_expand(args.body)
				end,
			},
			mapping = cmp.mapping.preset.insert({
				["<c-space>"] = cmp.mapping.complete(),
				["<CR>"] = cmp.mapping.confirm({
					behavior = cmp.ConfirmBehavior.Replace,
					select = false,
				}),
			}),
			sources = cmp.config.sources({
				{ name = "nvim_lsp" },
			}, {
				{ name = "buffer" },
			}),
		})

		vim.diagnostic.config({
			update_in_insert = true,
			virtual_text = false,
			float = {
				focusable = false,
				style = "minimal",
				border = "rounded",
				source = "always",
				header = "",
				prefix = "",
			},
		})

		require("which-key").add({
			{
				"<leader><leader>",
				function()
					require("lsp_lines").toggle()
				end,
				desc = "Toggle line diagnostics",
				mode = "n",
			},
			{ mode = "n" },
			{
				"gd",
				function()
					vim.lsp.buf.definition()
				end,
				desc = "Go to Definition",
			},
			{
				"K",
				function()
					vim.lsp.buf.hover()
				end,
				desc = "Hover Information",
			},
			{ "<leader>v", group = "LSP Actions" },
			{
				"<leader>vws",
				function()
					vim.lsp.buf.workspace_symbol()
				end,
				desc = "Workspace Symbol",
			},
			{
				"<leader>vd",
				function()
					vim.diagnostic.open_float()
				end,
				desc = "Open Diagnostic Float",
			},
			{
				"<leader>ca",
				function()
					vim.lsp.buf.code_action()
				end,
				desc = "Code Action",
			},
			{
				"<leader>vrr",
				function()
					vim.lsp.buf.references()
				end,
				desc = "Find References",
			},
			{
				"<leader>vrn",
				function()
					vim.lsp.buf.rename()
				end,
				desc = "Rename Symbol",
			},
			{
				"[d",
				function()
					vim.diagnostic.goto_next()
				end,
				desc = "Next Diagnostic",
			},
			{
				"]d",
				function()
					vim.diagnostic.goto_prev()
				end,
				desc = "Previous Diagnostic",
			},

			-- Insert mode LSP keymaps
			{ mode = "i" },
			{
				"<C-h>",
				function()
					vim.lsp.buf.signature_help()
				end,
				desc = "Signature Help",
			},
		})
	end,
}
