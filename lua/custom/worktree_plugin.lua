-- ~/.config/nvim/lua/custom/worktree.lua
-- Git Worktree Manager for Neovim with Snacks Picker
-- A comprehensive plugin for managing git worktrees with an intuitive picker interface

---@class Worktree
---@field path string Absolute path to the worktree
---@field head string|nil SHA of the current HEAD commit
---@field branch string|nil Name of the checked out branch
---@field detached boolean|nil Whether HEAD is detached
---@field current boolean|nil Whether this is the current worktree

---@class WorktreePickerItem
---@field file string Path for picker (usually worktree path)
---@field text string Fallback text display
---@field worktree Worktree The worktree data
---@field relpath string Relative path from repo container

---@class WorktreeConfig
---@field keymaps table<string, string>|nil Key mappings for worktree actions

local M = {}

-- ============================================================================
-- Configuration
-- ============================================================================

---@type WorktreeConfig
M.config = {}

-- ============================================================================
-- Git Command Utilities
-- ============================================================================

---Execute a git command and return the output
---@param args string[] Git command arguments
---@param opts? {ignore_error?: boolean} Options for error handling
---@return string[]|nil output Command output lines, or nil on error
local function git_cmd(args, opts)
  opts = opts or {}
  local cmd = vim.list_extend({ 'git' }, args)
  local result = vim.fn.systemlist(cmd)
  local exit_code = vim.v.shell_error

  if exit_code ~= 0 then
    if not opts.ignore_error then
      vim.notify('Git command failed: ' .. table.concat(result, '\n'), vim.log.levels.ERROR)
    end
    return nil
  end

  return result
end

-- ============================================================================
-- Path Utilities
-- ============================================================================

---Get the root directory of the main worktree
---@return string|nil root_dir The root directory path
local function get_repo_root_dir()
  local out = git_cmd({ 'worktree', 'list', '--porcelain' }, { ignore_error = true })
  if not out then
    return nil
  end

  for _, line in ipairs(out) do
    local wt = line:match '^worktree (.+)$'
    if wt then
      return vim.fn.fnamemodify(wt, ':p:h')
    end
  end

  return nil
end

---Get the container directory (parent of main worktree)
---@return string|nil container_dir The container directory path
local function get_repo_container_dir()
  local out = git_cmd({ 'worktree', 'list', '--porcelain' }, { ignore_error = true })
  if not out then
    return nil
  end

  for _, line in ipairs(out) do
    local wt = line:match '^worktree (.+)$'
    if wt then
      return vim.fn.fnamemodify(wt, ':p:h:h')
    end
  end

  return nil
end

---Convert worktree path to relative path from repo container
---@param worktree_path string Absolute path to worktree
---@param withContainerDir? boolean Include repo root in relative path
---@return string relative_path Relative path or fallback
local function path_from_repo_container(worktree_path, withContainerDir)
  local base = get_repo_container_dir()
  if not withContainerDir then
    base = get_repo_root_dir()
  end
  if not base then
    return vim.fn.fnamemodify(worktree_path, ':~')
  end

  base = vim.fn.fnamemodify(base, ':p')
  local wt = vim.fn.fnamemodify(worktree_path, ':p')

  if not base:match '/$' then
    base = base .. '/'
  end

  if vim.startswith(wt, base) then
    local rel = wt:sub(#base + 1)
    return rel ~= '' and rel or vim.fn.fnamemodify(worktree_path, ':t')
  end

  return vim.fn.fnamemodify(worktree_path, ':~')
end

-- ============================================================================
-- Worktree Parsing
-- ============================================================================

---Parse git worktree list output into structured data
---@return Worktree[] worktrees List of parsed worktrees
local function parse_worktrees()
  local output = git_cmd { 'worktree', 'list', '--porcelain' }
  if not output then
    return {}
  end

  local worktrees = {}
  local current_item = { current = false }
  local cwd = vim.fn.fnamemodify(vim.fn.getcwd(), ':p')

  for _, line in ipairs(output) do
    if line:match '^worktree ' then
      current_item.path = line:match '^worktree (.+)$'
    elseif line:match '^HEAD ' then
      current_item.head = line:match '^HEAD (.+)$'
    elseif line:match '^branch ' then
      current_item.branch = line:match '^branch refs/heads/(.+)$'
    elseif line:match '^detached' then
      current_item.detached = true
    elseif line == '' and current_item.path then
      -- Check if this is the current worktree
      if vim.fn.fnamemodify(current_item.path, ':p') == cwd then
        current_item.current = true
      end
      table.insert(worktrees, current_item)
      current_item = { current = false }
    end
  end

  -- Add last entry if exists
  if current_item.path then
    if vim.fn.fnamemodify(current_item.path, ':p') == cwd then
      current_item.current = true
    end
    table.insert(worktrees, current_item)
  end

  return worktrees
end

---Filter out bare worktrees (those without branches)
---@param worktrees Worktree[] List of worktrees
---@return Worktree[] filtered Non-bare worktrees only
local function filter_bare_worktrees(worktrees)
  local filtered = {}
  for _, wt in ipairs(worktrees) do
    if wt.branch or wt.detached then
      table.insert(filtered, wt)
    end
  end
  return filtered
end

-- ============================================================================
-- Formatting
-- ============================================================================

---Format worktree for simple text display
---@param wt Worktree The worktree to format
---@param withContainerDir? boolean Include repo root in relative path
---@return string formatted Formatted string
local function format_worktree(wt, withContainerDir)
  local marker = wt.current and '󰄳 ' or '  '
  local branch = wt.branch or (wt.detached and 'DETACHED') or 'bare'
  if branch ~= 'bare' then
    branch = ' ' .. branch
  end
  local sha = wt.head and wt.head:sub(1, 8) or ''
  if sha ~= '' then
    sha = ' ' .. sha
  end
  local path = ' ' .. path_from_repo_container(wt.path, withContainerDir)

  return string.format('%s%-30s %-25s %-8s', marker, path, branch, sha)
end

---Format worktree for picker display with syntax highlighting
---@param item WorktreePickerItem The picker item
---@param ctx table Picker context
---@return table[] highlights Array of highlight segments
local function format_worktree_picker(item, ctx)
  local a = require('snacks').picker.util.align
  local ret = {} ---@type snacks.picker.Highlight[]

  local wt = item.worktree
  if not wt then
    return { { item.text or '' } }
  end

  local win = ctx and ctx.win or 0
  local total = vim.api.nvim_win_get_width(win > 0 and win or 0)

  -- Responsive column sizing
  local marker_w = 2
  local sha_w = 8
  local path_w = math.max(22, math.floor(total * 0.35))
  local branch_w = math.max(20, total - (marker_w + path_w + sha_w + 6))

  -- Current worktree indicator
  if wt.current then
    ret[#ret + 1] = { a('󰄳 ', marker_w), 'SnacksPickerGitBranchCurrent' }
  else
    ret[#ret + 1] = { a('  ', marker_w) }
  end

  -- Relative path (dimmed)
  ret[#ret + 1] = {
    a(' ' .. item.relpath, path_w, { truncate = true }),
    'Comment',
  }

  ret[#ret + 1] = { ' ' }

  -- Branch name
  local branch = wt.branch or (wt.detached and 'DETACHED') or 'bare'
  ret[#ret + 1] = {
    a(' ' .. branch, branch_w, { truncate = true }),
    'SnacksPickerGitBranch',
  }

  ret[#ret + 1] = { ' ' }

  -- Commit SHA
  local sha = wt.head and wt.head:sub(1, 8) or ''
  ret[#ret + 1] = {
    a(' ' .. sha, sha_w),
    'SnacksPickerGitCommit',
  }

  return ret
end

-- ============================================================================
-- Worktree Operations
-- ============================================================================

---Switch to a worktree directory
---@param picker table The picker instance
---@param worktree Worktree The worktree to switch to
local function switch_to_worktree(picker, worktree)
  vim.cmd('cd ' .. vim.fn.fnameescape(worktree.path))
  vim.notify('Switched to worktree: ' .. worktree.path, vim.log.levels.INFO)
  picker:close()
end

---Delete a worktree with safety checks
---@param picker table The picker instance
---@param worktree Worktree The worktree to delete
local function delete_worktree(picker, worktree)
  if not worktree or not worktree.path then
    vim.notify('Invalid worktree: ' .. vim.inspect(worktree), vim.log.levels.ERROR)
    return
  end

  local display = format_worktree(worktree, true)

  -- Check worktree status
  local current_dir = vim.fn.getcwd()
  vim.cmd('cd ' .. vim.fn.fnameescape(worktree.path))
  local status_result = git_cmd({ 'status', '--porcelain' }, { ignore_error = true })
  local is_dirty = status_result and #status_result > 0
  vim.cmd('cd ' .. vim.fn.fnameescape(current_dir))

  -- Check if locked
  local worktree_info = git_cmd({ 'worktree', 'list', '--porcelain' }, { ignore_error = true })
  local is_locked = false
  if worktree_info then
    local in_target = false
    for _, line in ipairs(worktree_info) do
      if line:match '^worktree ' and line:find(worktree.path, 1, true) then
        in_target = true
      elseif in_target and line:match '^locked' then
        is_locked = true
        break
      elseif in_target and line == '' then
        break
      end
    end
  end

  -- Confirm deletion
  vim.ui.select({ 'Yes', 'No' }, {
    prompt = 'Delete worktree: ' .. display .. '?',
  }, function(confirm)
    if confirm ~= 'Yes' then
      return
    end

    ---Execute worktree deletion
    ---@param force boolean Whether to force deletion
    ---@return boolean success Whether deletion succeeded
    local function do_delete(force)
      local cmd_args = { 'worktree', 'remove' }
      if force then
        table.insert(cmd_args, '--force')
      end
      table.insert(cmd_args, worktree.path)

      local result = git_cmd(cmd_args, { ignore_error = true })
      if not result then
        vim.notify('Failed to delete worktree', vim.log.levels.ERROR)
        return false
      end

      vim.notify('Worktree deleted: ' .. worktree.path, vim.log.levels.INFO)
      return true
    end

    ---Finish deletion process (branch cleanup and picker refresh)
    local function finish_deletion()
      if worktree.branch then
        vim.ui.select({ 'Yes', 'No' }, {
          prompt = "Delete branch '" .. worktree.branch .. "' as well?",
        }, function(delete_branch)
          if delete_branch == 'Yes' then
            git_cmd { 'branch', '-D', worktree.branch }
            vim.notify('Branch deleted: ' .. worktree.branch, vim.log.levels.INFO)
          end

          picker:close()
          vim.schedule(function()
            M.manage()
          end)
        end)
      else
        picker:close()
        vim.schedule(function()
          M.manage()
        end)
      end
    end

    -- Handle dirty or locked worktrees
    if is_dirty or is_locked then
      local reason = is_locked and 'locked' or 'dirty (has uncommitted changes)'
      vim.ui.select({ 'Yes', 'No' }, {
        prompt = 'Worktree is ' .. reason .. '. Force delete?',
      }, function(force_confirm)
        if force_confirm == 'Yes' then
          if do_delete(true) then
            finish_deletion()
          else
            picker:close()
          end
        else
          picker:close()
        end
      end)
    else
      if do_delete(false) then
        finish_deletion()
      else
        picker:close()
      end
    end
  end)
end

-- ============================================================================
-- Public API
-- ============================================================================

---Create a new worktree interactively
function M.create_worktree()
  local branches = git_cmd { 'branch', '-a', '--format=%(refname:short)' }
  if not branches then
    return
  end

  -- Remove duplicates and clean branch names
  local seen = {}
  local clean_branches = {}
  for _, branch in ipairs(branches) do
    local clean = branch:gsub('^remotes/[^/]+/', '')
    if not seen[clean] then
      seen[clean] = true
      table.insert(clean_branches, clean)
    end
  end

  -- Select base branch
  vim.ui.select(clean_branches, {
    prompt = ' Select base branch: ',
  }, function(base_branch)
    if not base_branch then
      return
    end

    -- Get new branch name
    vim.ui.input({
      prompt = ' New branch name (leave empty to checkout existing): ',
      default = '',
    }, function(new_branch)
      if new_branch == nil then
        return
      end

      -- Get worktree directory
      local repo_base = get_repo_root_dir()
      local default_path = repo_base and (repo_base .. '/') or './'
      local suggested_dir = default_path
      if new_branch ~= '' then
        suggested_dir = vim.fn.fnamemodify(default_path, ':p') .. new_branch
      end

      vim.ui.input({
        prompt = ' Worktree directory: ',
        default = suggested_dir,
        completion = 'dir',
      }, function(wt_path)
        if not wt_path then
          return
        end

        wt_path = vim.fn.expand(wt_path)

        -- If checking out existing branch, ask about upstream
        if new_branch == '' then
          vim.ui.select({ 'Yes', 'No' }, {
            prompt = ' Set an upstream branch?',
          }, function(set_upstream)
            if set_upstream == 'Yes' then
              -- Get list of remote branches for upstream selection
              local remote_branches = git_cmd { 'branch', '-r', '--format=%(refname:short)' }
              if not remote_branches then
                vim.notify('Failed to fetch remote branches', vim.log.levels.ERROR)
                return
              end

              -- Clean remote branch names
              local clean_remote_branches = {}
              for _, remote_branch in ipairs(remote_branches) do
                -- Skip HEAD references
                if not remote_branch:match 'HEAD' then
                  table.insert(clean_remote_branches, remote_branch)
                end
              end

              vim.ui.select(clean_remote_branches, {
                prompt = ' Select upstream branch: ',
              }, function(upstream_branch)
                if not upstream_branch then
                  -- Create worktree without upstream
                  local cmd_args = { 'worktree', 'add', wt_path, base_branch }
                  local result = git_cmd(cmd_args)
                  if result then
                    vim.notify('Worktree created successfully', vim.log.levels.INFO)
                    vim.cmd('cd ' .. vim.fn.fnameescape(wt_path))
                  end
                  return
                end

                -- Create worktree first
                local cmd_args = { 'worktree', 'add', wt_path, base_branch }
                local result = git_cmd(cmd_args)
                if result then
                  -- Change to worktree directory and set upstream
                  local current_dir = vim.fn.getcwd()
                  vim.cmd('cd ' .. vim.fn.fnameescape(wt_path))

                  local upstream_result = git_cmd { 'branch', '--set-upstream-to=' .. upstream_branch }
                  if upstream_result then
                    vim.notify('Worktree created and upstream set to ' .. upstream_branch, vim.log.levels.INFO)
                  else
                    vim.notify('Worktree created but failed to set upstream', vim.log.levels.WARN)
                  end
                end
              end)
            else
              -- Create worktree without upstream
              local cmd_args = { 'worktree', 'add', wt_path, base_branch }
              local result = git_cmd(cmd_args)
              if result then
                vim.notify('Worktree created successfully', vim.log.levels.INFO)
                vim.cmd('cd ' .. vim.fn.fnameescape(wt_path))
              end
            end
          end)
        else
          -- Creating new branch - original behavior
          local cmd_args = { 'worktree', 'add', '-b', new_branch, wt_path, base_branch }
          local result = git_cmd(cmd_args)
          if result then
            vim.notify('Worktree created successfully', vim.log.levels.INFO)
            vim.cmd('cd ' .. vim.fn.fnameescape(wt_path))
          end
        end
      end)
    end)
  end)
end

---Open the worktree management picker
function M.manage()
  local snacks_ok, snacks = pcall(require, 'snacks')
  if not snacks_ok then
    vim.notify('Snacks.nvim is required for this plugin', vim.log.levels.ERROR)
    return
  end

  local worktrees = filter_bare_worktrees(parse_worktrees())
  if #worktrees == 0 then
    vim.notify('No non-bare worktrees found', vim.log.levels.WARN)
    return
  end

  local items = {}
  for _, wt in ipairs(worktrees) do
    table.insert(items, {
      file = wt.path,
      text = format_worktree(wt, false),
      worktree = wt,
      relpath = path_from_repo_container(wt.path, false),
    })
  end

  snacks.picker.pick {
    prompt = ' Git Worktrees ',
    items = items,
    preview = false,
    format = format_worktree_picker,
    confirm = function(picker, item)
      if item and item.worktree then
        switch_to_worktree(picker, item.worktree)
      end
    end,
    actions = {
      delete_worktree_action = function(picker)
        local item = picker:current()
        if item and item.worktree then
          delete_worktree(picker, item.worktree)
        end
      end,
    },
    win = {
      input = {
        keys = {
          ['<c-d>'] = { 'delete_worktree_action', mode = { 'n', 'i' } },
        },
      },
    },
  }
end

---Open the quick worktree switcher
function M.switch()
  local snacks_ok, snacks = pcall(require, 'snacks')
  if not snacks_ok then
    vim.notify('Snacks.nvim is required for this plugin', vim.log.levels.ERROR)
    return
  end

  local worktrees = filter_bare_worktrees(parse_worktrees())
  if #worktrees == 0 then
    vim.notify('No non-bare worktrees found', vim.log.levels.WARN)
    return
  end

  local items = {}
  for _, wt in ipairs(worktrees) do
    table.insert(items, {
      file = wt.path,
      text = format_worktree(wt, false),
      worktree = wt,
      relpath = path_from_repo_container(wt.path),
    })
  end

  snacks.picker.pick {
    prompt = ' Switch Worktree ',
    items = items,
    preview = false,
    format = format_worktree_picker,
    on_select = function(item, ctx)
      if item and item.worktree then
        switch_to_worktree(ctx.picker, item.worktree)
      end
    end,
  }
end

---List all worktrees in a floating window
function M.list()
  local worktrees = parse_worktrees()
  if #worktrees == 0 then
    vim.notify('No worktrees found', vim.log.levels.WARN)
    return
  end

  local lines = {}
  for _, wt in ipairs(worktrees) do
    table.insert(lines, format_worktree(wt, true))
  end

  -- Create scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'gitworktrees')

  -- Open floating window
  local width = math.min(120, vim.o.columns - 4)
  local height = math.min(#lines + 2, vim.o.lines - 6)

  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    style = 'minimal',
    border = 'rounded',
  })
end

---Setup the plugin with configuration
---@param opts? WorktreeConfig Configuration options
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend('force', M.config, opts)

  -- Create user commands
  vim.api.nvim_create_user_command('GitWorktreeManage', M.manage, {
    desc = 'Open git worktree manager',
  })
  vim.api.nvim_create_user_command('GitWorktreeSwitch', M.switch, {
    desc = 'Quick switch between worktrees',
  })
  vim.api.nvim_create_user_command('GitWorktreeCreate', M.create_worktree, {
    desc = 'Create a new worktree',
  })
  vim.api.nvim_create_user_command('GitWorktreeList', M.list, {
    desc = 'List all worktrees in a floating window',
  })

  -- Set up keymaps if provided
  if opts.keymaps then
    for key, action in pairs(opts.keymaps) do
      if M[action] then
        vim.keymap.set('n', key, M[action], { desc = 'Git Worktree: ' .. action })
      end
    end
  end
end

return M
