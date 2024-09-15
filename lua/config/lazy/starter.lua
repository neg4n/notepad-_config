return {
	"echasnovski/mini.starter",
	version = "*",
	opts = {},
	config = function()
		local starter = require("mini.starter")

		local function get_datetime_info()
			return os.date("!%Y-%m-%dT%H:%M:%SZ"), os.date("%Y-%m-%dT%H:%M:%S%z")
		end

		local function copy_to_clipboard(text)
			vim.fn.setreg("+", text)
			print("Copied to clipboard: " .. text)
		end

		local function custom_header()
			local utc_datetime, local_datetime = get_datetime_info()
			local username = os.getenv("USER") or os.getenv("USERNAME") or "user"
			return string.format(
				[[
UTC:    %s   (Press 'u' to copy)
Local:  %s   (Press 'l' to copy)

Welcome, %s! Let's make something amazing today!
  ]],
				utc_datetime,
				local_datetime,
				username
			)
		end

		local function shorten_path(path)
			local components = {}
			for component in path:gmatch("[^/]+") do
				table.insert(components, component)
			end

			for i = 1, #components do
				local component = components[i]
				if component:match("^%.") or component:match("^_") then
					components[i] = component:sub(1, 2)
				elseif i < #components then
					components[i] = component:sub(1, 1)
				end
			end

			return " → " .. "/" .. table.concat(components, "/")
		end

		starter.setup({
			evaluate_single = true,
			header = custom_header,
			items = {
				starter.sections.builtin_actions(),
				function()
					return starter.sections.recent_files(5, false, function(path)
						local relative_path = vim.fn.fnamemodify(path, ":~:.")
						return shorten_path(relative_path)
					end)()
				end,
			},
			content_hooks = {
				starter.gen_hook.adding_bullet("■ "),
				starter.gen_hook.aligning("center", "center"),
			},
			footer = [[
<Up>/<Down> to move • <Enter> to select • <Esc> to reset
Have a wonderful coding session!
  ]],
			query_updaters = "abcdefghijklmnopqrstuvwxyz_-.",
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "MiniStarterOpened",
			callback = function()
				local utc_datetime, local_datetime = get_datetime_info()

				vim.keymap.set("n", "u", function()
					copy_to_clipboard(utc_datetime)
				end, { buffer = true })
				vim.keymap.set("n", "l", function()
					copy_to_clipboard(local_datetime)
				end, { buffer = true })

				vim.cmd([[highlight link MiniStarterItemPrefix Comment]])
			end,
		})
	end,
}

