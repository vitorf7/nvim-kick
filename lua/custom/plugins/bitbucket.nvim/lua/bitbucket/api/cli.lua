local M = {}
local utils = require("bitbucket.utils")
local config = require("bitbucket.config")

M.cli_cmd = nil

-- Setup CLI wrapper
function M.setup()
  M.cli_cmd = config.values.cli_cmd
end

-- Execute a bb CLI command
function M.call(opts, callback)
  opts = opts or {}
  
  -- Convert API endpoint to CLI command
  local cli_args = M.endpoint_to_cli_args(opts)
  if not cli_args then
    callback(false, nil, "Cannot convert endpoint to CLI command: " .. opts.endpoint)
    return
  end
  
  -- Add JSON output flag
  table.insert(cli_args, "--json")
  
  -- Execute CLI command
  utils.run_async(M.cli_cmd, cli_args, function(success, output, err)
    if not success then
      callback(false, nil, err or "CLI command failed")
      return
    end
    
    -- Parse JSON output
    if output and output ~= "" then
      local ok, data = pcall(vim.json.decode, output)
      if ok then
        callback(true, data, nil)
      else
        callback(true, { raw = output }, nil)
      end
    else
      callback(true, {}, nil)
    end
  end, { timeout = config.values.api_timeout })
end

-- Convert API endpoint to CLI arguments
function M.endpoint_to_cli_args(opts)
  local endpoint = opts.endpoint
  local method = opts.method or "GET"
  local body = opts.body
  
  -- Pull requests
  if endpoint:match("/repositories/([^/]+)/([^/]+)/pullrequests$") then
    return { "pr", "list" }
  end
  
  if endpoint:match("/repositories/([^/]+)/([^/]+)/pullrequests/(%d+)$") then
    local workspace, repo, pr_id = endpoint:match("/repositories/([^/]+)/([^/]+)/pullrequests/(%d+)$")
    return { "pr", "view", pr_id, "--repo", workspace .. "/" .. repo }
  end
  
  if endpoint:match("/repositories/([^/]+)/([^/]+)/pullrequests/(%d+)/comments$") then
    local workspace, repo, pr_id = endpoint:match("/repositories/([^/]+)/([^/]+)/pullrequests/(%d+)/comments$")
    if method == "GET" then
      return { "pr", "comment", "list", pr_id, "--repo", workspace .. "/" .. repo }
    elseif method == "POST" then
      -- For creating comments via CLI, we might need to use the API directly
      return nil
    end
  end
  
  if endpoint:match("/repositories/([^/]+)/([^/]+)/pullrequests/(%d+)/approve$") then
    local workspace, repo, pr_id = endpoint:match("/repositories/([^/]+)/([^/]+)/pullrequests/(%d+)/approve$")
    if method == "POST" then
      return { "pr", "approve", pr_id, "--repo", workspace .. "/" .. repo }
    elseif method == "DELETE" then
      return { "pr", "unapprove", pr_id, "--repo", workspace .. "/" .. repo }
    end
  end
  
  if endpoint:match("/repositories/([^/]+)/([^/]+)/pullrequests/(%d+)/merge$") then
    local workspace, repo, pr_id = endpoint:match("/repositories/([^/]+)/([^/]+)/pullrequests/(%d+)/merge$")
    if method == "POST" then
      local args = { "pr", "merge", pr_id, "--repo", workspace .. "/" .. repo }
      if body and body.merge_strategy then
        table.insert(args, "--strategy")
        table.insert(args, body.merge_strategy)
      end
      return args
    end
  end
  
  -- Issues
  if endpoint:match("/repositories/([^/]+)/([^/]+)/issues$") then
    return { "issue", "list" }
  end
  
  if endpoint:match("/repositories/([^/]+)/([^/]+)/issues/(%d+)$") then
    local workspace, repo, issue_id = endpoint:match("/repositories/([^/]+)/([^/]+)/issues/(%d+)$")
    return { "issue", "view", issue_id, "--repo", workspace .. "/" .. repo }
  end
  
  -- Workspaces
  if endpoint == "/workspaces" then
    return { "workspace", "list" }
  end
  
  -- Repositories
  if endpoint:match("/repositories/([^/]+)$") then
    local workspace = endpoint:match("/repositories/([^/]+)$")
    return { "repo", "list", "--workspace", workspace }
  end
  
  -- If we can't convert to CLI, return nil to trigger REST fallback
  return nil
end

-- Execute raw CLI command with arguments
function M.execute(args, callback)
  utils.run_async(M.cli_cmd, args, callback, { timeout = config.values.api_timeout })
end

-- Check CLI version
function M.check_version(callback)
  utils.run_async(M.cli_cmd, { "version", "--json" }, function(success, output, err)
    if not success then
      callback(false, nil, err)
      return
    end
    
    local ok, version_info = pcall(vim.json.decode, output)
    if ok then
      callback(true, version_info, nil)
    else
      callback(false, nil, "Cannot parse version info")
    end
  end)
end

-- Login via CLI
function M.login(callback)
  utils.run_async(M.cli_cmd, { "auth", "login" }, function(success, _, err)
    if success then
      callback(true, nil, nil)
    else
      callback(false, nil, err or "Login failed")
    end
  end)
end

-- Logout via CLI
function M.logout(callback)
  utils.run_async(M.cli_cmd, { "auth", "logout" }, function(success, _, err)
    if success then
      callback(true, nil, nil)
    else
      callback(false, nil, err or "Logout failed")
    end
  end)
end

return M
