local M = {}

_G.bitbucket_buffers = {}
_G.bitbucket_reviews = {}

function M.setup(opts)
  opts = opts or {}
  
  -- Check Neovim version
  if vim.fn.has("nvim-0.10") ~= 1 then
    vim.notify("bitbucket.nvim requires Neovim 0.10+", vim.log.levels.ERROR)
    return
  end
  
  -- Setup configuration
  local config = require("bitbucket.config")
  config.setup(opts)
  
  -- Setup authentication
  local auth = require("bitbucket.auth")
  auth.setup()
  
  -- Setup API layer
  local api = require("bitbucket.api")
  api.setup()
  
  -- Setup pickers
  local picker = require("bitbucket.picker")
  picker.setup()
  
  -- Setup commands
  local commands = require("bitbucket.commands")
  commands.setup()
  
  -- Setup autocommands
  local autocmds = require("bitbucket.autocmds")
  autocmds.setup()
  
  -- Setup UI
  require("bitbucket.ui.colors").setup()
  require("bitbucket.ui.signs").setup()
  
  vim.notify("bitbucket.nvim loaded successfully", vim.log.levels.INFO)
end

-- Global buffer access helper
function M.get_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return _G.bitbucket_buffers[bufnr]
end

-- Check if buffer is a bitbucket buffer
function M.is_bitbucket_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  return ft == "bitbucket" or ft == "bitbucket-review"
end

-- Refresh current buffer
function M.refresh_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local buffer = M.get_buffer(bufnr)
  if buffer and buffer.refresh then
    buffer:refresh()
  end
end

return M
