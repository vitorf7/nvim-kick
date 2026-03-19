local M = {}
local utils = require("bitbucket.utils")

-- Default picker using vim.ui.select

function M.pick(opts)
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

function M.pick_multi(opts)
  -- vim.ui.select doesn't support multi-select
  -- Use multiple pick calls
  local selected = {}
  
  local function pick_next()
    local remaining = {}
    for _, item in ipairs(opts.items or {}) do
      if not vim.tbl_contains(selected, item) then
        table.insert(remaining, item)
      end
    end
    
    if #remaining == 0 then
      if opts.action then
        opts.action(selected)
      end
      return
    end
    
    vim.ui.select(remaining, {
      prompt = opts.prompt or "Select (or press ESC to finish):",
      format_item = opts.format or tostring,
    }, function(choice)
      if choice then
        table.insert(selected, choice)
        pick_next()
      else
        -- ESC pressed, finish selection
        if opts.action then
          opts.action(selected)
        end
      end
    end)
  end
  
  pick_next()
end

function M.list(opts)
  M.pick(opts)
end

function M.search(opts)
  M.pick(opts)
end

function M.fzf(opts)
  -- For default picker, use pick with items
  M.pick(opts)
end

return M
