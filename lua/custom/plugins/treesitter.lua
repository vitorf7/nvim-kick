return {
  'nvim-treesitter/nvim-treesitter',
  build = ':TSUpdate',
  event = 'VeryLazy',
  config = function()
    local filetypes = {
      'bash',
      'c',
      'cmake',
      'css',
      'diff',
      'dockerfile',
      'dot',
      'go',
      'godot_resource',
      'gomod',
      'gosum',
      'gowork',
      'hcl',
      'html',
      'javascript',
      'jsdoc',
      'json',
      'json5',
      'lua',
      'luadoc',
      'make',
      'markdown',
      'markdown_inline',
      'proto',
      'query',
      'scss',
      'sql',
      'terraform',
      'toml',
      'tsx',
      'typescript',
      'vim',
      'vimdoc',
      'yaml',
    }

    require('nvim-treesitter').install(filetypes)
    vim.api.nvim_create_autocmd('FileType', {
      pattern = filetypes,
      callback = function() vim.treesitter.start() end,
    })
  end,
}
