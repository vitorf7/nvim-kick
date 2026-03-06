-- Package.json scripts runner
-- Uses snacks.nvim picker for consistent UI
-- Supports npm, yarn, and pnpm
-- This is a utility module, not a plugin spec

local M = {}

-- Detect package manager based on lock files
function M.detect_package_manager()
  local cwd = vim.fn.getcwd()

  if vim.fn.filereadable(cwd .. '/pnpm-lock.yaml') == 1 then
    return 'pnpm'
  elseif vim.fn.filereadable(cwd .. '/yarn.lock') == 1 then
    return 'yarn'
  elseif vim.fn.filereadable(cwd .. '/package-lock.json') == 1 then
    return 'npm'
  else
    return 'npm' -- Default fallback
  end
end

-- Find nearest package.json (useful for monorepos)
function M.find_package_json()
  local current_file = vim.fn.expand '%:p'
  local current_dir = vim.fn.fnamemodify(current_file, ':h')

  -- Start from current file directory and traverse up
  local dir = current_dir
  while dir ~= '/' and dir ~= '' do
    local package_json = dir .. '/package.json'
    if vim.fn.filereadable(package_json) == 1 then
      return package_json, dir
    end
    dir = vim.fn.fnamemodify(dir, ':h')
  end

  -- Fall back to cwd
  local cwd_package = vim.fn.getcwd() .. '/package.json'
  if vim.fn.filereadable(cwd_package) == 1 then
    return cwd_package, vim.fn.getcwd()
  end

  return nil, nil
end

-- Parse scripts from package.json
function M.parse_scripts(package_json_path)
  if not package_json_path then
    vim.notify('No package.json found', vim.log.levels.WARN)
    return {}
  end

  local content = vim.fn.readfile(package_json_path)
  local ok, json = pcall(vim.fn.json_decode, table.concat(content, '\n'))

  if not ok or not json or not json.scripts then
    vim.notify('Failed to parse package.json or no scripts found', vim.log.levels.WARN)
    return {}
  end

  local scripts = {}
  for name, cmd in pairs(json.scripts) do
    table.insert(scripts, {
      name = name,
      command = cmd,
      display = string.format('%-20s %s', name, cmd),
    })
  end

  -- Sort by name
  table.sort(scripts, function(a, b) return a.name < b.name end)

  return scripts
end

-- Run a script
function M.run_script(script_name, cwd, background)
  local package_manager = M.detect_package_manager()
  local cmd

  -- Handle package managers with different syntaxes
  if package_manager == 'npm' then
    cmd = string.format('npm run %s', script_name)
  else
    -- yarn and pnpm use same syntax
    cmd = string.format('%s %s', package_manager, script_name)
  end

  -- Change to project directory if different from cwd
  if cwd and cwd ~= vim.fn.getcwd() then
    cmd = string.format('cd %s && %s', vim.fn.shellescape(cwd), cmd)
  end

  if background then
    -- Run in background using Jobstart or termopen
    vim.fn.jobstart(cmd, {
      cwd = cwd or vim.fn.getcwd(),
      on_exit = function(_, code)
        if code == 0 then
          vim.notify(string.format('✓ %s completed', script_name), vim.log.levels.INFO)
        else
          vim.notify(string.format('✗ %s failed (exit %d)', script_name, code), vim.log.levels.ERROR)
        end
      end,
    })
    vim.notify(string.format('Running %s in background...', script_name), vim.log.levels.INFO)
  else
    -- Open in terminal
    vim.cmd 'botright split'
    vim.cmd('term ' .. cmd)
    vim.cmd 'startinsert'
  end
end

-- Main function to show picker
function M.show_scripts_picker()
  local package_json, project_dir = M.find_package_json()
  local scripts = M.parse_scripts(package_json)

  if #scripts == 0 then
    vim.notify('No scripts found in package.json', vim.log.levels.WARN)
    return
  end

  local package_manager = M.detect_package_manager()
  local items = {}

  for _, script in ipairs(scripts) do
    table.insert(items, {
      text = script.display,
      script = script,
      cwd = project_dir,
      pm = package_manager,
    })
  end

  Snacks.picker({
    items = items,
    title = string.format('Package Scripts (%s)', package_manager),
    layout = {
      preview = false,
    },
    format = function(item)
      return { { item.text, 'Normal' } }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        M.run_script(item.script.name, item.cwd, false)
      end
    end,
    actions = {
      -- Run in background with <C-b>
      run_background = function(picker)
        local item = picker:current()
        if item then
          M.run_script(item.script.name, item.cwd, true)
          picker:close()
        end
      end,
      -- Show command details with <C-d>
      show_details = function(picker)
        local item = picker:current()
        if item then
          vim.notify(string.format('Command: %s\nPackage Manager: %s', item.script.command, item.pm), vim.log.levels.INFO)
        end
      end,
    },
  })
end

return M
