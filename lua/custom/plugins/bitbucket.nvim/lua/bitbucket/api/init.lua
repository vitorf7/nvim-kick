local M = {}
local utils = require("bitbucket.utils")
local config = require("bitbucket.config")
local auth = require("bitbucket.auth")
local constants = require("bitbucket.constants")

M.use_cli = false
M.cli_available = false

-- Setup API layer
function M.setup()
  -- Check if CLI is available
  M.cli_available = utils.command_exists(config.values.cli_cmd)
  
  -- Determine whether to use CLI or REST
  M.use_cli = config.values.prefer_cli and M.cli_available
  
  if M.use_cli then
    utils.debug("Using bb CLI for API calls")
    require("bitbucket.api.cli").setup()
  else
    utils.debug("Using REST API for calls")
    require("bitbucket.api.rest").setup()
  end
  
  -- Load endpoint modules
  M.pullrequests = require("bitbucket.api.endpoints.pullrequests")
  M.comments = require("bitbucket.api.endpoints.comments")
  M.issues = require("bitbucket.api.endpoints.issues")
  M.workspaces = require("bitbucket.api.endpoints.workspaces")
end

-- Generic API call with CLI/REST fallback
function M.call(opts, callback)
  opts = opts or {}
  
  -- Check authentication first
  if not auth.is_authenticated() then
    callback(false, nil, "Not authenticated. Run :Bitbucket auth login")
    return
  end
  
  -- Try CLI first if preferred
  if M.use_cli and M.cli_available then
    local cli = require("bitbucket.api.cli")
    cli.call(opts, function(success, data, err)
      if success then
        callback(true, data, nil)
      else
        -- CLI failed, try REST as fallback
        utils.debug("CLI failed, falling back to REST: " .. (err or "unknown"))
        M.rest_call(opts, callback)
      end
    end)
  else
    -- Use REST directly
    M.rest_call(opts, callback)
  end
end

-- REST API call
function M.rest_call(opts, callback)
  local rest = require("bitbucket.api.rest")
  rest.call(opts, callback)
end

-- Synchronous API call (for simple operations)
function M.call_sync(opts)
  local result = nil
  local error_msg = nil
  local done = false
  
  M.call(opts, function(success, data, err)
    if success then
      result = data
    else
      error_msg = err
    end
    done = true
  end)
  
  -- Wait for async operation with timeout
  local timeout = config.values.api_timeout or 10000
  local start = vim.loop.now()
  
  while not done do
    vim.loop.sleep(10)
    if vim.loop.now() - start > timeout then
      return nil, "API call timed out"
    end
  end
  
  return result, error_msg
end

-- Get current platform
function M.get_platform()
  return auth.platform
end

-- Check if using CLI
function M.is_using_cli()
  return M.use_cli
end

-- Set platform preference manually
function M.set_platform(platform)
  if platform ~= "cloud" and platform ~= "datacenter" then
    utils.error("Invalid platform: " .. platform)
    return false
  end
  
  auth.platform = platform
  utils.info("Platform set to: " .. platform)
  return true
end

-- Health check
function M.health_check()
  local results = {
    cli_available = M.cli_available,
    using_cli = M.use_cli,
    authenticated = auth.is_authenticated(),
    platform = auth.platform,
  }
  
  -- Test API connection
  if auth.is_authenticated() then
    local test_opts = {
      method = "GET",
      endpoint = auth.platform == "cloud" and "/repositories/atlassian/hello-world" or "/projects",
    }
    
    M.call(test_opts, function(success, _, err)
      results.api_working = success
      if not success then
        results.error = err
      end
    end)
  end
  
  return results
end

return M
