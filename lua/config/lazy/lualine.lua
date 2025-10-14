return {
    "nvim-lualine/lualine.nvim",
    opts = {
        theme = "everforest",
        options = {
            -- Powerline-style triangles connected to filled rectangles.
            -- See lualine docs: section_separators/component_separators. 
            -- Use triangles for section boundaries, no inner component separators.
            section_separators = { left = "", right = "" },
            component_separators = { left = "", right = "" },
        },
        sections = {
            lualine_a = { 'mode' },
            lualine_b = { 'branch', 'diff' },
            lualine_c = {
                {
                    'diagnostics',
                    sources = { 'nvim_diagnostic' },
                    symbols = {
                        error = '✕ ',
                        warn  = '⚠ ',
                        info  = ' ',
                        hint  = ' ',
                    },
                },
            },
            lualine_x = {
                -- BIOME status component
                {
                    function()
                        local ft = vim.bo.filetype or ""
                        local js_like = { javascript=true, javascriptreact=true, typescript=true, typescriptreact=true, vue=true, svelte=true, astro=true, jsx=true, tsx=true }
                        local biome_on = false
                        if js_like[ft] then
                            local fname = vim.api.nvim_buf_get_name(0)
                            if fname == "" then fname = vim.fn.expand("%:p") end
                            local dir = (fname ~= "" and vim.fs.dirname(fname)) or vim.loop.cwd()
                            local found = vim.fs.find({ "biome.json", "biome.jsonc" }, { upward = true, path = dir })
                            biome_on = (#found > 0) and (vim.fn.executable("biome") == 1)
                        end
                        return string.format("BIOME %s", biome_on and "ON" or "OFF")
                    end,
                    color = function()
                        -- ON -> white; OFF -> dimmed (Comment fg)
                        local ft = vim.bo.filetype or ""
                        local js_like = { javascript=true, javascriptreact=true, typescript=true, typescriptreact=true, vue=true, svelte=true, astro=true, jsx=true, tsx=true }
                        local biome_on = false
                        if js_like[ft] then
                            local fname = vim.api.nvim_buf_get_name(0)
                            if fname == "" then fname = vim.fn.expand("%:p") end
                            local dir = (fname ~= "" and vim.fs.dirname(fname)) or vim.loop.cwd()
                            local found = vim.fs.find({ "biome.json", "biome.jsonc" }, { upward = true, path = dir })
                            biome_on = (#found > 0) and (vim.fn.executable("biome") == 1)
                        end
                        if biome_on then
                            return { fg = "#FFFFFF" }
                        else
                            local c = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
                            local fg = c and c.fg and string.format("#%06x", c.fg) or nil
                            return { fg = fg }
                        end
                    end,
                    padding = { left = 1, right = 0 },
                },
                -- Pipe separator
                {
                    function() return "|" end,
                    color = function()
                        local c = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
                        local fg = c and c.fg and string.format("#%06x", c.fg) or nil
                        return { fg = fg }
                    end,
                    padding = { left = 1, right = 1 },
                },
                -- ESLINT status component
                {
                    function()
                        local cwd = vim.loop.cwd()
                        local biome_root = vim.fs.find({ "biome.json", "biome.jsonc" }, { upward = true, path = cwd })
                        local eslint_on = (#biome_root == 0)
                        return string.format("ESLINT %s", eslint_on and "ON" or "OFF")
                    end,
                    color = function()
                        local cwd = vim.loop.cwd()
                        local biome_root = vim.fs.find({ "biome.json", "biome.jsonc" }, { upward = true, path = cwd })
                        local eslint_on = (#biome_root == 0)
                        if eslint_on then
                            return { fg = "#FFFFFF" }
                        else
                            local c = vim.api.nvim_get_hl(0, { name = "Comment", link = false })
                            local fg = c and c.fg and string.format("#%06x", c.fg) or nil
                            return { fg = fg }
                        end
                    end,
                    padding = { left = 0, right = 1 },
                },
            },
            -- Keep other sections as they were...
        },
    },
    dependencies = { "nvim-tree/nvim-web-devicons" },
}
