return {
  'NvChad/nvim-colorizer.lua',
  ft = { 'css', 'scss', 'sass', 'less', 'html', 'javascript', 'typescript', 'javascriptreact', 'typescriptreact', 'lua', 'json', 'yaml' },
  opts = {
    filetypes = { 
      '*', 
      '!lazy',
      -- Per-filetype overrides
      html = { mode = 'background' },
      css = { mode = 'background' },
    },
    buftypes = {},
    user_commands = true,
    lazy_load = false,
    options = {
      parsers = {
        -- Enable CSS preset (names, hex, rgb, hsl, oklch)
        css = {
          enable = true,
          names = { enable = false },  -- We don't want names
        },
        -- Hex formats
        hex = {
          enable = true,
          rgb = true,      -- #RGB
          rgba = true,     -- #RGBA
          rrggbb = true,   -- #RRGGBB
          rrggbbaa = true, -- #RRGGBBAA
          aarrggbb = true, -- 0xAARRGGBB
        },
        -- RGB functions
        rgb = { enable = true },
        -- HSL functions
        hsl = { enable = true },
        -- Tailwind
        tailwind = {
          enable = true,
          lsp = false,  -- Don't use Tailwind LSP
          update_names = false,
        },
      },
      display = {
        mode = 'background',  -- "background"|"foreground"|"virtualtext"
        background = {
          bright_fg = '#000000',
          dark_fg = '#ffffff',
        },
        priority = {
          default = 150,  -- vim.hl.priorities.diagnostics
          lsp = 200,      -- vim.hl.priorities.user
        },
      },
      hooks = {
        should_highlight_line = false,
      },
      always_update = false,
    },
  },
}
