local M = {}
local utils = require("bitbucket.utils")

-- Telescope picker implementation

function M.pick(opts)
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    require("bitbucket.pickers.default").pick(opts)
    return
  end
  
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  
  local items = opts.items or {}
  local format = opts.format or function(item)
    return tostring(item)
  end
  
  -- Prepare entries
  local entry_maker = function(item)
    local formatted = format(item)
    return {
      value = item,
      display = formatted,
      ordinal = formatted,
    }
  end
  
  pickers.new({}, {
    prompt_title = opts.prompt or "Select",
    finder = finders.new_table({
      results = items,
      entry_maker = entry_maker,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection and opts.action then
          opts.action(selection.value)
        end
      end)
      return true
    end,
  }):find()
end

function M.pick_multi(opts)
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    require("bitbucket.pickers.default").pick_multi(opts)
    return
  end
  
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")
  
  local items = opts.items or {}
  local format = opts.format or function(item)
    return tostring(item)
  end
  
  local entry_maker = function(item)
    local formatted = format(item)
    return {
      value = item,
      display = formatted,
      ordinal = formatted,
    }
  end
  
  pickers.new({}, {
    prompt_title = opts.prompt or "Select (Tab to toggle, Enter to confirm)",
    finder = finders.new_table({
      results = items,
      entry_maker = entry_maker,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(prompt_bufnr, map)
      -- Multi-select with Tab
      map("i", "<Tab>", actions.toggle_selection)
      map("n", "<Tab>", actions.toggle_selection)
      
      actions.select_default:replace(function()
        local selections = action_state.get_selected_entries()
        actions.close(prompt_bufnr)
        
        local selected_items = {}
        for _, selection in ipairs(selections) do
          table.insert(selected_items, selection.value)
        end
        
        if #selected_items > 0 and opts.action then
          opts.action(selected_items)
        end
      end)
      return true
    end,
  }):find()
end

function M.list(opts)
  local ok, telescope = pcall(require, "telescope")
  if not ok then
    require("bitbucket.pickers.default").list(opts)
    return
  end
  
  -- Use generic pick with the provided items
  M.pick({
    items = opts.items,
    prompt = opts.title or "Select",
    format = opts.entry_maker and function(item)
      local entry = opts.entry_maker(item)
      return entry.display or entry.value
    end or nil,
    action = opts.actions and function(item)
      -- Default action
      for _, action_def in pairs(opts.actions) do
        if action_def.default then
          action_def.action(item)
          return
        end
      end
    end or nil,
  })
end

function M.search(opts)
  -- For now, delegate to default
  require("bitbucket.pickers.default").search(opts)
end

function M.fzf(opts)
  -- Telescope doesn't do FZF, fallback to pick
  M.pick(opts)
end

return M
