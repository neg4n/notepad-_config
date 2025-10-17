return {
	"zbirenbaum/copilot.lua",
	dependencies = {
		"copilotlsp-nvim/copilot-lsp",
	},
	event = "InsertEnter",
	opts = {
		suggestion = {
			auto_trigger = true,
			debounce = 70,
		},
		nes = {
			enabled = true,
			auto_trigger = true,
		},
		copilot_node_command = "bun --bunx",
	},
}
