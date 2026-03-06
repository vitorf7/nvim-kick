return {
  {
    'hrsh7th/nvim-cmp',
    optional = true,
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      table.insert(opts.sources, {
        name = 'lazydev',
        group_index = 0,
      })
    end,
  },
  {
    'saghen/blink.cmp',
    event = 'InsertEnter',
    version = '*',
    dependencies = {
      {
        'L3MON4D3/LuaSnip',
        version = 'v2.*',
        dependencies = {
          'rafamadriz/friendly-snippets',
          config = function()
            require('luasnip.loaders.from_vscode').lazy_load()
            require('luasnip.loaders.from_vscode').load { paths = { vim.fn.stdpath('config') .. '/snippets' } }
          end,
        },
        build = (function()
          if vim.fn.has 'win32' == 1 or vim.fn.executable 'make' == 0 then
            return
          end
          return 'make install_jsregexp'
        end)(),
      },
      {
        'saghen/blink.compat',
        optional = true,
        opts = {},
        version = '*',
      },
      'moyiz/blink-emoji.nvim',
    },
    opts = function(_, opts)
      local icons = require('util').icons.kinds
      
      ---@module 'blink.cmp'
      ---@type blink.cmp.Config
      local myopts = {
        signature = { enabled = true },
        
        appearance = {
          use_nvim_cmp_as_default = false,
          nerd_font_variant = 'mono',
          kind_icons = icons,
        },
        
        completion = {
          accept = {
            auto_brackets = {
              enabled = true,
            },
          },
          menu = {
            draw = {
              columns = { { 'label', 'label_description', gap = 1 }, { 'kind_icon', 'kind' } },
              treesitter = { 'lsp' },
            },
          },
          documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
          },
        },
        
        snippets = {
          expand = function(snippet)
            require('luasnip').lsp_expand(snippet)
          end,
          active = function(filter)
            if filter and filter.direction then
              return require('luasnip').jumpable(filter.direction)
            end
            return require('luasnip').in_snippet()
          end,
          jump = function(direction)
            require('luasnip').jump(direction)
          end,
        },
        
        sources = {
          default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer', 'emoji', 'markdown' },
          providers = {
            lazydev = {
              name = 'LazyDev',
              module = 'lazydev.integrations.blink',
              score_offset = 100,
            },
            emoji = {
              module = 'blink-emoji',
              name = 'Emoji',
              score_offset = 15,
              opts = { insert = true },
            },
            markdown = {
              name = 'RenderMarkdown',
              module = 'render-markdown.integ.blink',
              fallbacks = { 'lsp' },
            },
          },
        },
        
        keymap = {
          preset = 'default',
          ['<Tab>'] = {},
          ['<S-Tab>'] = {},
          ['<C-y>'] = { 'select_and_accept' },
          ['<C-n>'] = { 'select_next', 'fallback' },
          ['<C-p>'] = { 'select_prev', 'fallback' },
          ['<C-j>'] = { 'select_next', 'fallback' },
          ['<C-k>'] = { 'select_prev', 'fallback' },
          ['<C-l>'] = {
            function(cmp)
              if cmp.snippet_active() then
                return cmp.accept()
              else
                return cmp.select_and_accept()
              end
            end,
            'snippet_forward',
            'fallback',
          },
          ['<C-h>'] = { 'snippet_backward', 'fallback' },
        },
      }
      
      opts = vim.tbl_extend('force', opts, myopts)
      return opts
    end,
    opts_extend = {
      'sources.completion.enabled_providers',
      'sources.compat',
      'sources.default',
    },
  },
}
