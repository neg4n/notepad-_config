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
		{ "iguanacucumber/magazine.nvim", name = "nvim-cmp" },
		"j-hui/fidget.nvim",
		"onsails/lspkind.nvim",
		"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
	},
	config = function()
		-- Add Mason bin to PATH
		local mason_bin = vim.fn.expand("$HOME/.local/share/nvim/mason/bin")
		vim.env.PATH = mason_bin .. ":" .. vim.env.PATH

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

		-- Detect a Biome config relative to the directory Neovim was launched from.
		-- If present, we will fully disable ESLint for this session (monorepo-friendly).
		local function find_biome_root_from_cwd()
			local cwd = vim.loop.cwd()
			local found = vim.fs.find({ "biome.json", "biome.jsonc" }, { upward = true, path = cwd })
			if #found > 0 then
				return vim.fs.dirname(found[1])
			end
			return nil
		end
		local SESSION_BIOME_ROOT = find_biome_root_from_cwd()

		-- As an extra safety net, kill any ESLint client that attaches when Biome is active for this session.
		if SESSION_BIOME_ROOT then
			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data and args.data.client_id or 0)
					if client and client.name == "eslint" then
						vim.schedule(function()
							client.stop(true)
						end)
					end
				end,
			})
		end
		require("mason").setup()
		require("mason-lspconfig").setup({
			ensure_installed = {
				"lua_ls",
				"vtsls",
				"tailwindcss",
				"eslint",
				"clangd",
				"cmake",
				"ruff",
				"astro",
				"cssls",
				"biome",
				"html",
			},
			handlers = {
				function(server_name)
					require("lspconfig")[server_name].setup({
						capabilities = capabilities,
					})
				end,

				-- Disable ts_ls explicitly (prefer vtsls)
				["ts_ls"] = function() end,

				["vtsls"] = function()
					require("lspconfig").vtsls.setup({
						capabilities = capabilities,
						filetypes = {
							"javascript",
							"javascriptreact",
							"javascript.jsx",
							"typescript",
							"typescriptreact",
							"typescript.tsx",
						},
					})
				end,

				["html"] = function()
					require("lspconfig").html.setup({
						capabilities = capabilities,
						filetypes = { "html" },
					})
				end,

				["cssls"] = function()
					require("lspconfig").cssls.setup({
						capabilities = capabilities,
						filetypes = { "css", "scss", "less" },
					})
				end,

				-- Only run ESLint when an ESLint config exists and no Biome config is present.
				["eslint"] = function()
					local lspconfig = require("lspconfig")
					local util = require("lspconfig.util")

					-- If Biome is configured anywhere from the launch CWD upwards,
					-- disable ESLint across the entire workspace/session.
					if SESSION_BIOME_ROOT then
						return
					end

					local eslint_root = util.root_pattern(
						".eslintrc",
						".eslintrc.json",
						".eslintrc.js",
						".eslintrc.cjs",
						".eslintrc.yaml",
						".eslintrc.yml",
						"eslint.config.js",
						"eslint.config.cjs",
						"eslint.config.mjs",
						"eslint.config.ts"
					)

					lspconfig.eslint.setup({
						capabilities = capabilities,
						root_dir = function(fname)
							-- If a Biome config is present for this file, skip ESLint entirely.
							local biome_root = util.root_pattern("biome.json", "biome.jsonc")(fname)
							if biome_root then
								return nil
							end
							return eslint_root(fname)
						end,
						settings = {
							eslint = {
								format = { enable = false },
								workingDirectories = { mode = "auto" },
							},
						},
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
			formatting = {
				format = require("lspkind").cmp_format({
					mode = "symbol",
					maxwidth = 50,
					ellipsis_char = "...",
					show_labelDetails = true,
				}),
			},
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

		local map = vim.keymap.set

		map("n", "<leader><leader>", function()
			require("lsp_lines").toggle()
		end, { desc = "Toggle line diagnostics" })

		map("n", "gd", function()
			vim.lsp.buf.definition()
		end, { desc = "Go to Definition" })

		map("n", "<leader>h", function()
			vim.lsp.buf.hover()
		end, { desc = "Hover Information" })


		map("n", "<leader>r", function()
		  vim.cmd.FormatWrite()
		end, { desc = "Format code" })

		map("n", "<leader>vws", function()
			vim.lsp.buf.workspace_symbol()
		end, { desc = "Workspace Symbol" })

		map("n", "<leader>vd", function()
			vim.diagnostic.open_float()
		end, { desc = "Open Diagnostic Float" })

		map("n", "<leader>ca", function()
			vim.lsp.buf.code_action()
		end, { desc = "Code Action" })

		map("n", "<leader>vrr", function()
			vim.lsp.buf.references()
		end, { desc = "Find References" })

		map("n", "<leader>vrn", function()
			vim.lsp.buf.rename()
		end, { desc = "Rename Symbol" })

		map("n", "[d", function()
			vim.diagnostic.goto_next()
		end, { desc = "Next Diagnostic" })

		map("n", "]d", function()
			vim.diagnostic.goto_prev()
		end, { desc = "Previous Diagnostic" })

		map("i", "<C-h>", function()
			vim.lsp.buf.signature_help()
		end, { desc = "Signature Help" })
	end,
}
