return {
  'oskarrrrrrr/symbols.nvim',
  config = function()
    local r = require 'symbols.recipes'
    require('symbols').setup(r.DefaultFilters, r.AsciiSymbols, {
      sidebar = {
        -- custom settings here
      },
    })
  end,
  keys = {
    { '<leader>ls', '<cmd>Symbols<CR>', desc = '[L]SP [S]ymbols sidebar' },
    { '<leader>lS', '<cmd>SymbolsClose<CR>', desc = '[L]SP [S]ymbols close' },
  },
}
