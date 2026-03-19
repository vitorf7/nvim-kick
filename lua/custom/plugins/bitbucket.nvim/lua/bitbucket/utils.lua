local M = {}
local Job = require("plenary.job")

-- Debug logging
function M.debug(msg)
  if os.getenv("BITBUCKET_NVIM_DEBUG") then
    print("[bitbucket.nvim] " .. msg)
  end
end

-- Error notification
function M.error(msg)
  vim.notify("[bitbucket.nvim] " .. msg, vim.log.levels.ERROR)
end

-- Info notification
function M.info(msg)
  vim.notify("[bitbucket.nvim] " .. msg, vim.log.levels.INFO)
end

-- Warning notification
function M.warn(msg)
  vim.notify("[bitbucket.nvim] " .. msg, vim.log.levels.WARN)
end

-- Get current git repository info
function M.get_git_info()
  local handle = io.popen("git remote -v 2>/dev/null")
  if not handle then
    return nil
  end
  
  local result = handle:read("*a")
  handle:close()
  
  if result == "" then
    return nil
  end
  
  -- Parse remote URLs to extract workspace/project and repo
  local remotes = {}
  for line in result:gmatch("[^\r\n]+") do
    local name, url = line:match("(%S+)%s+(%S+)%s+")
    if name and url then
      table.insert(remotes, { name = name, url = url })
    end
  end
  
  return remotes
end

-- Parse Bitbucket URL to extract components
function M.parse_url(url)
  if not url then
    return nil
  end
  
  local constants = require("bitbucket.constants")
  
  -- Try Cloud PR URL
  local workspace, repo, pr_id = url:match(constants.URL_PATTERNS.cloud_pr)
  if workspace and repo and pr_id then
    return {
      platform = constants.PLATFORM_CLOUD,
      workspace = workspace,
      repo = repo,
      pr_id = tonumber(pr_id),
      type = "pull_request",
    }
  end
  
  -- Try Data Center PR URL
  local host, project, dc_repo, dc_pr_id = url:match(constants.URL_PATTERNS.datacenter_pr)
  if host and project and dc_repo and dc_pr_id then
    return {
      platform = constants.PLATFORM_DATACENTER,
      host = host,
      project = project,
      repo = dc_repo,
      pr_id = tonumber(dc_pr_id),
      type = "pull_request",
    }
  end
  
  -- Try Cloud repo URL
  workspace, repo = url:match(constants.URL_PATTERNS.cloud_repo)
  if workspace and repo then
    return {
      platform = constants.PLATFORM_CLOUD,
      workspace = workspace,
      repo = repo,
      type = "repo",
    }
  end
  
  -- Try Data Center repo URL
  host, project, dc_repo = url:match(constants.URL_PATTERNS.datacenter_repo)
  if host and project and dc_repo then
    return {
      platform = constants.PLATFORM_DATACENTER,
      host = host,
      project = project,
      repo = dc_repo,
      type = "repo",
    }
  end
  
  -- Try Cloud SSH URL (git@bitbucket.org:workspace/repo.git)
  workspace, repo = url:match(constants.URL_PATTERNS.cloud_repo_ssh)
  if workspace and repo then
    return {
      platform = constants.PLATFORM_CLOUD,
      workspace = workspace,
      repo = repo,
      type = "repo",
    }
  end
  
  -- Try Data Center SSH URL
  project, dc_repo = url:match(constants.URL_PATTERNS.datacenter_repo_ssh)
  if project and dc_repo then
    return {
      platform = constants.PLATFORM_DATACENTER,
      project = project,
      repo = dc_repo,
      type = "repo",
    }
  end
  
  return nil
end

-- Run shell command asynchronously
function M.run_async(cmd, args, callback, opts)
  opts = opts or {}
  
  local stdout_lines = {}
  local stderr_lines = {}
  
  local job = Job:new({
    command = cmd,
    args = args,
    cwd = opts.cwd,
    env = opts.env,
    on_stdout = function(_, line)
      table.insert(stdout_lines, line)
    end,
    on_stderr = function(_, line)
      table.insert(stderr_lines, line)
    end,
    on_exit = function(j, return_val)
      vim.schedule(function()
        if return_val == 0 then
          local output = table.concat(stdout_lines, "\n")
          callback(true, output, nil)
        else
          local error_output = table.concat(stderr_lines, "\n")
          if error_output == "" then
            error_output = table.concat(stdout_lines, "\n")
          end
          callback(false, nil, error_output)
        end
      end)
    end,
  })
  
  job:start()
  
  if opts.timeout then
    vim.defer_fn(function()
      if job.is_shutdown ~= true then
        job:shutdown()
        callback(false, nil, "Command timed out after " .. opts.timeout .. "ms")
      end
    end, opts.timeout)
  end
  
  return job
end

-- Run shell command synchronously
function M.run_sync(cmd, args, opts)
  opts = opts or {}
  
  local stdout_lines = {}
  local stderr_lines = {}
  local return_val = nil
  
  local job = Job:new({
    command = cmd,
    args = args,
    cwd = opts.cwd,
    env = opts.env,
    on_stdout = function(_, line)
      table.insert(stdout_lines, line)
    end,
    on_stderr = function(_, line)
      table.insert(stderr_lines, line)
    end,
    on_exit = function(j, val)
      return_val = val
    end,
  })
  
  local timeout = opts.timeout or 30000
  job:sync(timeout)
  
  if return_val == 0 then
    return true, table.concat(stdout_lines, "\n"), nil
  else
    local error_output = table.concat(stderr_lines, "\n")
    if error_output == "" then
      error_output = table.concat(stdout_lines, "\n")
    end
    return false, nil, error_output
  end
end

-- Check if command exists
function M.command_exists(cmd)
  local handle = io.popen("command -v " .. cmd .. " 2>/dev/null")
  if not handle then
    return false
  end
  local result = handle:read("*a")
  handle:close()
  return result ~= ""
end

-- Deep merge tables
function M.merge_tables(t1, t2)
  local result = {}
  for k, v in pairs(t1 or {}) do
    result[k] = v
  end
  for k, v in pairs(t2 or {}) do
    if type(v) == "table" and type(result[k]) == "table" then
      result[k] = M.merge_tables(result[k], v)
    else
      result[k] = v
    end
  end
  return result
end

-- Get visual selection
function M.get_visual_selection()
  local mode = vim.api.nvim_get_mode().mode
  local start_pos = vim.api.nvim_buf_get_mark(0, "<")
  local end_pos = vim.api.nvim_buf_get_mark(0, ">")
  
  if mode == "V" or mode == "\22" then
    -- Line-wise or block-wise visual mode
    local lines = vim.api.nvim_buf_get_lines(0, start_pos[1] - 1, end_pos[1], false)
    return table.concat(lines, "\n")
  else
    -- Character-wise visual mode
    local lines = vim.api.nvim_buf_get_lines(0, start_pos[1] - 1, end_pos[1], false)
    if #lines == 0 then
      return ""
    elseif #lines == 1 then
      return lines[1]:sub(start_pos[2] + 1, end_pos[2] + 1)
    else
      lines[1] = lines[1]:sub(start_pos[2] + 1)
      lines[#lines] = lines[#lines]:sub(1, end_pos[2] + 1)
      return table.concat(lines, "\n")
    end
  end
end

-- Split string by delimiter
function M.split(str, delimiter)
  local result = {}
  for match in (str .. delimiter):gmatch("(.-)" .. delimiter) do
    table.insert(result, match)
  end
  return result
end

-- Trim whitespace from string
function M.trim(s)
  return s:match("^%s*(.-)%s*$")
end

-- Check if table contains value
function M.table_contains(tbl, value)
  for _, v in ipairs(tbl) do
    if v == value then
      return true
    end
  end
  return false
end

-- Format date to relative time
function M.format_relative_time(date_str)
  if not date_str then
    return ""
  end
  
  -- Parse ISO 8601 format
  local year, month, day, hour, min, sec = date_str:match("(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)")
  if not year then
    return date_str
  end
  
  local time_table = {
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec),
  }
  
  local timestamp = os.time(time_table)
  local now = os.time()
  local diff = now - timestamp
  
  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local mins = math.floor(diff / 60)
    return mins .. " minute" .. (mins == 1 and "" or "s") .. " ago"
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours .. " hour" .. (hours == 1 and "" or "s") .. " ago"
  elseif diff < 604800 then
    local days = math.floor(diff / 86400)
    return days .. " day" .. (days == 1 and "" or "s") .. " ago"
  else
    return os.date("%b %d, %Y", timestamp)
  end
end

-- Make HTTP request using curl
function M.http_request(method, url, body, headers, callback)
  headers = headers or {}
  
  local args = {
    "-s", "-L", -- Silent, follow redirects
    "-X", method,
    "-w", "\\n%{http_code}", -- Output status code on last line
  }
  
  -- Add headers
  for key, value in pairs(headers) do
    table.insert(args, "-H")
    table.insert(args, key .. ": " .. value)
  end
  
  -- Add body for POST/PUT/PATCH
  if body and (method == "POST" or method == "PUT" or method == "PATCH") then
    table.insert(args, "-d")
    table.insert(args, body)
  end
  
  table.insert(args, url)
  
  M.run_async("curl", args, function(success, output, error)
    if not success then
      callback(false, nil, error)
      return
    end
    
    -- Parse response (body + status code)
    local lines = M.split(output, "\n")
    local status_code = tonumber(lines[#lines])
    table.remove(lines)
    local body_text = table.concat(lines, "\n")
    
    if status_code >= 200 and status_code < 300 then
      callback(true, { status = status_code, body = body_text }, nil)
    else
      callback(false, { status = status_code, body = body_text }, "HTTP " .. status_code)
    end
  end, { timeout = 30000 })
end

-- Escape special characters for shell
function M.shell_escape(str)
  return str:gsub("([\"'])", "\\%1")
end

-- Get current working directory
function M.get_cwd()
  return vim.fn.getcwd()
end

-- Check if current directory is a git repo
function M.is_git_repo()
  local success = M.run_sync("git", { "rev-parse", "--git-dir" }, { timeout = 5000 })
  return success
end

-- Get current branch name
function M.get_current_branch()
  local success, output, _ = M.run_sync("git", { "branch", "--show-current" }, { timeout = 5000 })
  if success then
    return M.trim(output)
  end
  return nil
end

-- Copy text to system clipboard
function M.copy_to_clipboard(text)
  vim.fn.setreg("+", text)
  vim.fn.setreg("*", text)
  M.info("Copied to clipboard: " .. text:sub(1, 50) .. (text:len() > 50 and "..." or ""))
end

-- Open URL in browser
function M.open_in_browser(url)
  local cmd
  if vim.fn.has("mac") == 1 then
    cmd = "open"
  elseif vim.fn.has("unix") == 1 then
    cmd = "xdg-open"
  elseif vim.fn.has("win32") == 1 then
    cmd = "start"
  else
    M.error("Cannot open browser on this platform")
    return
  end
  
  local success, _, err = M.run_sync(cmd, { url }, { timeout = 5000 })
  if not success then
    M.error("Failed to open browser: " .. (err or "unknown error"))
  end
end

-- Create a floating window
function M.create_floating_window(opts)
  opts = opts or {}
  
  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.8)
  local col = opts.col or math.floor((vim.o.columns - width) / 2)
  local row = opts.row or math.floor((vim.o.lines - height) / 2)
  
  local bufnr = opts.bufnr or vim.api.nvim_create_buf(false, true)
  
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = opts.border or "rounded",
  }
  
  local winnr = vim.api.nvim_open_win(bufnr, true, win_opts)
  
  return {
    bufnr = bufnr,
    winnr = winnr,
  }
end

-- Close floating window
function M.close_floating_window(winnr)
  if vim.api.nvim_win_is_valid(winnr) then
    vim.api.nvim_win_close(winnr, true)
  end
end

-- State to highlight group mappings (octo-style)
M.state_hl_map = {
  OPEN = "BitbucketStateOpen",
  CLOSED = "BitbucketStateClosed",
  MERGED = "BitbucketStateMerged",
  DECLINED = "BitbucketStateDeclined",
  DRAFT = "BitbucketStateDraft",
  APPROVED = "BitbucketStateApproved",
  CHANGES_REQUESTED = "BitbucketStateChangesRequested",
  COMMENTED = "BitbucketStateCommented",
  PENDING = "BitbucketStatePending",
  SUBMITTED = "BitbucketStateSubmitted",
  DISMISSED = "BitbucketStateDismissed",
}

-- Viewed state to icon and highlight mappings (octo-style)
M.viewed_state_map = {
  VIEWED = { icon = "", hl = "BitbucketGreen" },
  UNVIEWED = { icon = "○", hl = "BitbucketBlue" },
  DISMISSED = { icon = "", hl = "BitbucketRed" },
}

-- Get highlight group for a state
function M.get_state_hl(state)
  return M.state_hl_map[state] or "BitbucketNormal"
end

-- Get icon and highlight for viewed state
function M.get_viewed_state(viewed_state)
  return M.viewed_state_map[viewed_state] or M.viewed_state_map.UNVIEWED
end

return M
