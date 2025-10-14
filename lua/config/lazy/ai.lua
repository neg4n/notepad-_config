return {
  'echasnovski/mini.ai',
  version = '*',
  event = 'VeryLazy',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'nvim-treesitter/nvim-treesitter-textobjects',
    'MunifTanjim/nui.nvim',
  },
  config = function()
    local ai = require('mini.ai')

    ai.setup({
      n_lines = 300,
      custom_textobjects = {
        t = ai.gen_spec.treesitter({ a = '@tag.outer',        i = '@tag.inner' }),
        f = ai.gen_spec.treesitter({ a = '@function.outer',   i = '@function.inner' }),
        c = ai.gen_spec.treesitter({ a = '@class.outer',      i = '@class.inner' }),
        o = ai.gen_spec.treesitter({
          a = { '@block.outer', '@conditional.outer', '@loop.outer' },
          i = { '@block.inner', '@conditional.inner', '@loop.inner' },
        }),
        a = ai.gen_spec.treesitter({ a = '@parameter.outer',  i = '@parameter.inner' }),
        s = ai.gen_spec.treesitter({ a = '@string.outer',     i = '@string.inner' }),
      },
    })

    -- Lightweight, instant, single-key, two-step picker using nui.nvim
    local Popup = require('nui.popup')
    local Text = require('nui.text')
    local event = require('nui.utils.autocmd').event

    -- Ensure popup-specific highlights (reuse your fzf-lua palette)
    pcall(vim.api.nvim_set_hl, 0, 'MiniAiPopup', { fg = '#FFFFFF', bg = '#000000' })

    local function open_popup(lines, title)
      local maxw = 0
      for _, l in ipairs(lines) do maxw = math.max(maxw, vim.fn.strdisplaywidth(l)) end
      local height = #lines
      local width = math.max(28, maxw + 2)

      local popup = Popup({
        enter = true,
        focusable = true,
        relative = 'editor',
        position = { row = '100%', col = '100%' },
        size = { width = width, height = height },
        border = {
          style = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" },
          text = { top = Text(' ' .. (title or 'Match') .. ' ', 'FzfLuaTitle'), top_align = 'center' },
        },
        zindex = 50,
        win_options = {
          winblend = 0,
          winhighlight = 'Normal:MiniAiPopup,FloatBorder:FzfLuaBorder,FloatTitle:FzfLuaTitle',
        },
      })

      popup:mount()
      -- ensure buffer is modifiable when writing, then lock it
      vim.bo[popup.bufnr].modifiable = true
      vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
      vim.bo[popup.bufnr].modifiable = false

      -- Close when focus leaves
      popup:on(event.BufLeave, function() popup:unmount() end, { once = true })
      return popup
    end

    local objects = {
      { key = 't', label = 'Tag (JSX/HTML/Vue/Svelte)' },
      { key = 'f', label = 'Function/Method' },
      { key = 'c', label = 'Class/Interface/Module' },
      { key = 'o', label = 'Block / Loop / Conditional' },
      { key = 'a', label = 'Argument / Parameter' },
      { key = 's', label = 'String' },
      { key = '(', label = 'Parentheses' },
      { key = '[', label = 'Brackets' },
      { key = '{', label = 'Braces' },
      { key = '<', label = 'Angle brackets' },
      { key = '"', label = 'Double quotes' },
      { key = "'", label = 'Single quotes' },
      { key = '`', label = 'Backticks' },
    }

    local function lines_for_object_menu()
      local lines = {}
      for _, o in ipairs(objects) do
        table.insert(lines, string.format('  %s  %s', o.key, o.label))
      end
      return lines
    end

    local function lines_for_scope_menu()
      return { '  i  inside', '  a  around' }
    end

    local function feed(keys)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), 'n', true)
    end

    local function run_selection(side, obj)
      local mode = vim.api.nvim_get_mode().mode
      local keys
      if mode:find('v') then
        keys = side .. obj
      elseif mode == 'n' then
        keys = 'v' .. side .. obj
      else
        keys = side .. obj
      end
      vim.schedule(function() feed(keys) end)
    end

    local function object_by_key(k)
      for _, o in ipairs(objects) do if o.key == k then return o.key end end
      return nil
    end

    local function map_keys(popup, mappings)
      for lhs, rhs in pairs(mappings) do
        popup:map('n', lhs, rhs, { nowait = true, noremap = true, silent = true })
      end
    end

    local origin_win = nil

    local function open_scope_menu(obj_key)
      local popup = open_popup(lines_for_scope_menu(), 'Scope')
      map_keys(popup, {
        ['i'] = function()
          popup:unmount()
          if origin_win and vim.api.nvim_win_is_valid(origin_win) then
            vim.api.nvim_set_current_win(origin_win)
          end
          run_selection('i', obj_key)
        end,
        ['a'] = function()
          popup:unmount()
          if origin_win and vim.api.nvim_win_is_valid(origin_win) then
            vim.api.nvim_set_current_win(origin_win)
          end
          run_selection('a', obj_key)
        end,
        ['<Esc>'] = function() popup:unmount() end,
        ['q'] = function() popup:unmount() end,
      })
    end

    local function open_object_menu()
      origin_win = vim.api.nvim_get_current_win()
      local popup = open_popup(lines_for_object_menu(), 'Match')
      local maps = {
        ['<Esc>'] = function() popup:unmount() end,
        ['q'] = function() popup:unmount() end,
      }
      for _, o in ipairs(objects) do
        maps[o.key] = function() popup:unmount(); open_scope_menu(o.key) end
      end
      map_keys(popup, maps)
    end

    local function match_picker()
      open_object_menu()
    end

    -- Single entry point `m` (normal/visual/operator-pending)
    vim.keymap.set({ 'n', 'x', 'o' }, 'm', match_picker, { desc = 'Match textobject' })
    vim.api.nvim_create_user_command('Match', match_picker, { desc = 'Open textobject matcher' })
  end,
}
