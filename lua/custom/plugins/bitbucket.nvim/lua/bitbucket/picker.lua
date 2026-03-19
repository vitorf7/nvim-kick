local M = {}
local config = require("bitbucket.config")
local utils = require("bitbucket.utils")

M.picker_type = nil
M.picker_module = nil

-- Setup picker
function M.setup()
  M.picker_type = config.values.picker
  
  -- Determine which picker is available
  if M.picker_type == "telescope" then
    local ok, _ = pcall(require, "telescope")
    if ok then
      M.picker_module = require("bitbucket.pickers.telescope")
    else
      utils.warn("Telescope not found, falling back to default picker")
      M.picker_type = "default"
    end
  elseif M.picker_type == "fzf-lua" then
    local ok, _ = pcall(require, "fzf-lua")
    if ok then
      M.picker_module = require("bitbucket.pickers.fzf-lua")
    else
      utils.warn("fzf-lua not found, falling back to default picker")
      M.picker_type = "default"
    end
  elseif M.picker_type == "snacks" then
    local ok, _ = pcall(require, "snacks")
    if ok then
      M.picker_module = require("bitbucket.pickers.snacks")
    else
      utils.warn("snacks.nvim not found, falling back to default picker")
      M.picker_type = "default"
    end
  end
  
  if M.picker_type == "default" or not M.picker_module then
    M.picker_module = require("bitbucket.pickers.default")
  end
end

-- Pick a single item from a list
-- @param opts.items table - List of items to pick from
-- @param opts.prompt string - Prompt text
-- @param opts.format function(item) -> string - Format function for display
-- @param opts.preview function(item) -> string|nil - Preview function
-- @param opts.action function(item) - Action to perform on selection
-- @param opts.cancel function() - Action on cancellation (optional)
function M.pick(opts)
  return M.picker_module.pick(opts)
end

-- Pick multiple items from a list
-- @param opts.items table - List of items
-- @param opts.prompt string
-- @param opts.format function(item) -> string
-- @param opts.action function(selected_items)
function M.pick_multi(opts)
  return M.picker_module.pick_multi(opts)
end

-- Generic list picker (for PRs, issues, etc.)
-- @param opts.title string - Window title
-- @param opts.items table - Items to display
-- @param opts.entry_maker function(item) -> table - Convert item to entry
-- @param opts.preview function(item) -> table - Preview configuration
-- @param opts.actions table - Key mappings to actions
function M.list(opts)
  return M.picker_module.list(opts)
end

-- Search picker
function M.search(opts)
  return M.picker_module.search(opts)
end

-- FZF picker (for fuzzy finding)
function M.fzf(opts)
  return M.picker_module.fzf(opts)
end

-- Default picker using vim.ui.select
local default_picker = {}

function default_picker.pick(opts)
  local items = opts.items or {}
  local format = opts.format or function(item)
    return tostring(item)
  end
  
  local formatted_items = {}
  local item_map = {}
  
  for i, item in ipairs(items) do
    local formatted = format(item)
    table.insert(formatted_items, formatted)
    item_map[formatted] = item
  end
  
  vim.ui.select(formatted_items, {
    prompt = opts.prompt or "Select:",
  }, function(choice)
    if choice then
      local item = item_map[choice]
      if opts.action then
        opts.action(item)
      end
    elseif opts.cancel then
      opts.cancel()
    end
  end)
end

function default_picker.pick_multi(opts)
  -- vim.ui.select doesn't support multi-select natively
  -- For now, just use single select
  default_picker.pick(opts)
end

function default_picker.list(opts)
  default_picker.pick(opts)
end

function default_picker.search(opts)
  default_picker.pick(opts)
end

function default_picker.fzf(opts)
  default_picker.pick(opts)
end

-- Register default picker
if not M.picker_module then
  M.picker_module = default_picker
end

return M
