local M = {}
local utils = require("bitbucket.utils")

-- fzf-lua picker implementation

function M.pick(opts)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    require("bitbucket.pickers.default").pick(opts)
    return
  end
  
  local items = opts.items or {}
  local format = opts.format or function(item)
    return tostring(item)
  end
  
  -- Format items
  local formatted = {}
  for i, item in ipairs(items) do
    formatted[i] = format(item)
  end
  
  fzf.fzf_exec(formatted, {
    prompt = opts.prompt or "Select » ",
    actions = {
      ["default"] = function(selected)
        -- Find the original item from selection
        for i, item in ipairs(items) do
          if format(item) == selected[1] then
            if opts.action then
              opts.action(item)
            end
            break
          end
        end
      end,
    },
  })
end

function M.pick_multi(opts)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    require("bitbucket.pickers.default").pick_multi(opts)
    return
  end
  
  local items = opts.items or {}
  local format = opts.format or function(item)
    return tostring(item)
  end
  
  -- Format items
  local formatted = {}
  for i, item in ipairs(items) do
    formatted[i] = format(item)
  end
  
  fzf.fzf_exec(formatted, {
    prompt = opts.prompt or "Select (Tab to toggle) » ",
    fzf_opts = {
      ["--multi"] = "",
    },
    actions = {
      ["default"] = function(selected)
        local selected_items = {}
        for _, sel in ipairs(selected) do
          for i, item in ipairs(items) do
            if format(item) == sel then
              table.insert(selected_items, item)
              break
            end
          end
        end
        
        if #selected_items > 0 and opts.action then
          opts.action(selected_items)
        end
      end,
    },
  })
end

function M.list(opts)
  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    require("bitbucket.pickers.default").list(opts)
    return
  end
  
  -- Delegate to pick with formatted items
  M.pick({
    items = opts.items,
    prompt = opts.title or "Select",
    format = opts.entry_maker and function(item)
      local entry = opts.entry_maker(item)
      return entry.display or entry.value
    end or nil,
    action = opts.action,
  })
end

function M.search(opts)
  -- For now, delegate to default
  require("bitbucket.pickers.default").search(opts)
end

function M.fzf(opts)
  -- fzf-lua is already fzf-based, use pick
  M.pick(opts)
end

return M
