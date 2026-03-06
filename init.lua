-- Neovim Configuration
-- Modular setup based on kickstart.nvim
-- vim: ts=2 sts=2 sw=2 et

-- Set <space> as the leader key
-- See `:help mapleader`
-- NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Load configuration modules
require 'config.options'
require 'config.keymaps'
require 'config.autocmds'
require 'config.lazy'
