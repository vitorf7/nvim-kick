local M = {
  'catppuccin/nvim',
  name = 'catppuccin',
  priority = 2000,
  ---@class CatppuccinOptions
  config = function()
    require('catppuccin').setup {
      flavour = 'mocha',
      transparent_background = true,
      -- custom_highlights = function(colors)
      --   return {
      --     CurSearch = { bg = colors.yellow },
      --     DiffChanged = { fg = colors.yellow },
      --     Diffchanged = { fg = colors.yellow },
      --   }
      -- end,
      integrations = {
        cmp = true,
        blink_cmp = true,
        fidget = true,
        gitsigns = true,
        harpoon = true,
        lsp_trouble = true,
        mason = true,
        neotest = true,
        noice = true,
        notify = true,
        octo = true,
        telescope = {
          enabled = true,
        },
        treesitter = true,
        treesitter_context = false,
        symbols_outline = true,
        illuminate = true,
        which_key = true,
        barbecue = {
          dim_dirname = true,
          bold_basename = true,
          dim_context = false,
          alt_background = false,
        },
        native_lsp = {
          enabled = true,
          virtual_text = {
            errors = { 'italic' },
            hints = { 'italic' },
            warnings = { 'italic' },
            information = { 'italic' },
          },
          underlines = {
            errors = { 'underline' },
            hints = { 'underline' },
            warnings = { 'underline' },
            information = { 'underline' },
          },
        },
      },
    }
    vim.cmd.colorscheme 'catppuccin'
  end,
}

return M
