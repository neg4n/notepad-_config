return {
	"windwp/nvim-ts-autotag",
  -- Lazy-load by filetype instead of events to avoid loading
  -- in buffers where autotag can never apply.
  ft = {
    "html",
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
    "vue",
    "svelte",
    "astro",
    "templ",
  },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("nvim-ts-autotag").setup({
      opts = {
        enable_close = true,
        enable_rename = true,
        enable_close_on_slash = false,
      },
      -- Teach autotag to treat `templ` like html
      aliases = {
        templ = "html",
      },
      -- Use per_filetype to tweak behavior later if needed
      -- per_filetype = { html = { enable_close = true } },
    })
  end,
}
