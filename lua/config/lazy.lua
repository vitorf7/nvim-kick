-- Lazy.nvim plugin manager setup
-- vim: ts=2 sts=2 sw=2 et

-- [[ Install lazy.nvim plugin manager ]]
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system { 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath }
  if vim.v.shell_error ~= 0 then error('Error cloning lazy.nvim:\n' .. out) end
end

---@type vim.Option
local rtp = vim.opt.rtp
rtp:prepend(lazypath)

vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  callback = function()
    -- vim.cmd [[command! -nargs=0 GoToCommand :Telescope commands]]
    vim.cmd [[command! -nargs=0 GoToCommand :lua Snacks.picker.commands()]]
    -- vim.cmd [[command! -nargs=0 GoToFile :Telescope smart_open]]
    vim.cmd [[command! -nargs=0 GoToFile :lua Snacks.picker.pick("smart")]]
    -- vim.cmd [[command! -nargs=0 Grep :Telescope live_grep]]
    vim.cmd [[command! -nargs=0 Grep :lua Snacks.picker.grep()]]
    vim.cmd [[command! -nargs=0 BrowseFiles :lua require('kickstart.config.modules.mini-files-explorer').open()]]
    vim.cmd [[command! -nargs=0 GenNvim :Gen]]
  end,
})

-- [[ Configure and install plugins ]]
require('lazy').setup {
  defaults = {
    lazy = true,
  },
  ui = {
    backdrop = 100,
  },
  spec = {
    { import = 'custom.plugins' },
  },
  checker = { enabled = true },
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        'editorconfig',
        'gzip',
        'man',
        'matchit',
        'matchparen',
        'netrwPlugin',
        'osc52',
        'rplugin',
        'spellfile',
        'tarPlugin',
        'tohtml',
        'tutor',
        'zipPlugin',
      },
    },
  },
}
