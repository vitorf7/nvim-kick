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

-- kevinhwang91/nvim-ufo (via kevinhwang91/promise-async) and
-- ThePrimeagen/refactoring.nvim (via lewis6991/async.nvim) both define a
-- Lua module named `async`, with incompatible APIs. Each plugin has several
-- submodules that lazily `require('async')` at different, unpredictable
-- times throughout the session (not just once at startup), so a single
-- global `package.loaded.async` cache slot can't serve both correctly --
-- whichever plugin's module wins the cache first, the other breaks later
-- with errors like "attempt to call upvalue 'async' (a table value)" or
-- "attempt to call field 'wrap' (a nil value)".
-- Intercept `require('async')` globally and resolve it fresh (bypassing the
-- cache) based on which plugin's file is asking, before any plugin loads.
do
  local original_require = require
  local data_dir = vim.fn.stdpath 'data'
  local promise_async_path = data_dir .. '/lazy/promise-async/lua/async.lua'
  local lewis_async_path = data_dir .. '/lazy/async.nvim/lua/async.lua'

  _G.require = function(modname)
    if modname == 'async' then
      local info = debug.getinfo(2, 'S')
      local caller = info and info.source or ''
      if caller:find('nvim-ufo', 1, true) or caller:find('promise-async', 1, true) then
        return dofile(promise_async_path)
      elseif caller:find('refactoring.nvim', 1, true) or caller:find('async.nvim', 1, true) then
        return dofile(lewis_async_path)
      end
    end
    return original_require(modname)
  end
end

vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  callback = function()
    -- vim.cmd [[command! -nargs=0 GoToCommand :Telescope commands]]
    vim.cmd [[command! -nargs=0 GoToCommand :lua Snacks.picker.commands()]]
    -- vim.cmd [[command! -nargs=0 GoToFile :Telescope smart_open]]
    vim.cmd [[command! -nargs=0 GoToFile :lua Snacks.picker.pick("smart")]]
    -- vim.cmd [[command! -nargs=0 Grep :Telescope live_grep]]
    vim.cmd [[command! -nargs=0 Grep :lua Snacks.picker.grep()]]
    vim.cmd [[command! -nargs=0 BrowseFiles :lua require('config.modules.mini-files-explorer').open()]]
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
