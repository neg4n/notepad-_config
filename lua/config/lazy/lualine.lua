return {
    "nvim-lualine/lualine.nvim",
    opts = {
        theme = "everforest",
        sections = {
            lualine_a = {'mode'},
            lualine_b = {'branch', 'diff'},
            lualine_c = {
                {
                    'diagnostics',
                    sources = {'nvim_diagnostic'},
                    symbols = {
                        error = '✕ ', -- You can use any icon you prefer
                        warn = '⚠ ',  -- These are examples, feel free to change
                        info = ' ',
                        hint = ' '
                    }
                }
            },
            -- Keep other sections as they were...
        }
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
}

