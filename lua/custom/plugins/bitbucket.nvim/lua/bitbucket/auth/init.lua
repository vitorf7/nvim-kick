local M = {}
local utils = require("bitbucket.utils")
local config = require("bitbucket.config")

M.auth_info = nil
M.platform = nil

-- Setup authentication
function M.setup()
  M.auth_info = M.detect_auth()
  M.platform = M.detect_platform()
  
  if not M.auth_info then
    utils.warn("No Bitbucket authentication detected. Set BB_API_TOKEN or run 'bb auth login'")
  end
end

-- Detect authentication method based on priority
function M.detect_auth()
  local auth_method = config.values.auth_method
  
  if auth_method == "auto" or auth_method == "env" then
    local env_auth = M.get_env_auth()
    if env_auth then
      utils.debug("Using environment variable authentication")
      return env_auth
    end
  end
  
  if auth_method == "auto" or auth_method == "cli" then
    local cli_auth = M.get_cli_auth()
    if cli_auth then
      utils.debug("Using CLI authentication")
      return cli_auth
    end
  end
  
  if auth_method == "auto" or auth_method == "config" then
    local config_auth = M.get_config_file_auth()
    if config_auth then
      utils.debug("Using config file authentication")
      return config_auth
    end
  end
  
  return nil
end

-- Get auth from environment variables
function M.get_env_auth()
  -- Bitbucket Cloud: API token (BB_API_TOKEN)
  local api_token = os.getenv("BB_API_TOKEN")
  local username = os.getenv("BB_USERNAME")
  
  if api_token then
    return {
      type = "api_token",
      token = api_token,
      username = username,
      platform = "cloud",
    }
  end
  
  -- Legacy: BITBUCKET_TOKEN (for backward compatibility)
  local legacy_token = os.getenv("BITBUCKET_TOKEN")
  if legacy_token then
    return {
      type = "api_token",
      token = legacy_token,
      username = nil,
      platform = "cloud",
    }
  end
  
  -- Bitbucket Data Center: Personal access token
  local dc_token = os.getenv("BITBUCKET_DC_TOKEN")
  if dc_token then
    return {
      type = "personal_token",
      token = dc_token,
      username = nil,
      platform = "datacenter",
    }
  end
  
  return nil
end

-- Get auth from bb CLI
function M.get_cli_auth()
  -- Check if bb CLI is installed and logged in
  if not utils.command_exists("bb") then
    return nil
  end
  
  local success, output, err = utils.run_sync("bb", { "auth", "status", "--json" }, { timeout = 5000 })
  if not success then
    return nil
  end
  
  local ok, status = pcall(vim.json.decode, output)
  if not ok or not status then
    return nil
  end
  
  if status.authenticated and status.user then
    return {
      type = "cli",
      cli_cmd = "bb",
      platform = "cloud",
      username = status.user.username,
      user = status.user,
    }
  end
  
  return nil
end

-- Get auth from config file
function M.get_config_file_auth()
  local config_path = vim.fn.expand("~/.config/bitbucket.nvim/config.json")
  
  local file = io.open(config_path, "r")
  if not file then
    return nil
  end
  
  local content = file:read("*a")
  file:close()
  
  local ok, data = pcall(vim.json.decode, content)
  if not ok or not data then
    return nil
  end
  
  -- API token (preferred)
  if data.api_token then
    return {
      type = "api_token",
      token = data.api_token,
      username = data.username,
      platform = data.platform or "cloud",
    }
  end
  
  -- Legacy OAuth token
  if data.token then
    return {
      type = "api_token",
      token = data.token,
      username = data.username,
      platform = data.platform or "cloud",
    }
  end
  
  -- Data Center personal token
  if data.personal_token then
    return {
      type = "personal_token",
      token = data.personal_token,
      username = data.username,
      platform = data.platform or "datacenter",
    }
  end
  
  return nil
end

-- Detect platform (Cloud vs Data Center)
function M.detect_platform()
  if M.auth_info and M.auth_info.platform then
    return M.auth_info.platform
  end
  
  local platform = config.values.platform
  if platform ~= "auto" then
    return platform
  end
  
  -- Try to detect from git remotes
  local remotes = utils.get_git_info()
  if remotes then
    for _, remote in ipairs(remotes) do
      if remote.url:match("bitbucket%.org") then
        return "cloud"
      elseif not remote.url:match("github%.com") then
        -- Non-bitbucket.org, non-github URL might be Data Center
        return "datacenter"
      end
    end
  end
  
  -- Default to Cloud
  return "cloud"
end

-- Get base URL for API requests
function M.get_base_url()
  if M.platform == "datacenter" and config.values.base_url then
    return config.values.base_url .. require("bitbucket.constants").DATACENTER_API_PATH
  end
  return require("bitbucket.constants").CLOUD_API_BASE
end

-- Get authorization headers for HTTP requests
function M.get_auth_headers()
  if not M.auth_info then
    return nil, "No authentication available"
  end
  
  local headers = {
    ["Accept"] = "application/json",
    ["Content-Type"] = "application/json",
  }
  
  if M.auth_info.type == "api_token" then
    -- Bitbucket API tokens use Basic auth with username:token
    if M.auth_info.username then
      local credentials = M.auth_info.username .. ":" .. M.auth_info.token
      local encoded = vim.base64.encode(credentials)
      headers["Authorization"] = "Basic " .. encoded
    else
      -- Try Bearer auth as fallback (for legacy tokens)
      headers["Authorization"] = "Bearer " .. M.auth_info.token
    end
  elseif M.auth_info.type == "personal_token" then
    -- Data Center tokens use Bearer
    headers["Authorization"] = "Bearer " .. M.auth_info.token
  end
  
  return headers, nil
end

-- Save auth to config file
function M.save_config_auth(auth_data)
  local config_dir = vim.fn.expand("~/.config/bitbucket.nvim")
  vim.fn.mkdir(config_dir, "p")
  
  local config_path = config_dir .. "/config.json"
  local file = io.open(config_path, "w")
  if not file then
    return false, "Cannot write config file"
  end
  
  file:write(vim.json.encode(auth_data))
  file:close()
  
  -- Secure the file
  vim.fn.system("chmod 600 " .. config_path)
  
  return true, nil
end

-- Interactive login prompt
function M.prompt_login()
  local platform = vim.fn.input("Platform (cloud/datacenter) [cloud]: ")
  if platform == "" then
    platform = "cloud"
  end
  
  if platform == "cloud" then
    local method = vim.fn.input("Auth method (token/cli) [token]: ")
    if method == "" then
      method = "token"
    end
    
    if method == "token" then
      -- Username is required for API token auth
      local username = vim.fn.input("Bitbucket Username: ")
      if username == "" then
        utils.error("Username is required for API token authentication")
        return
      end
      
      local token = vim.fn.inputsecret("Bitbucket API Token: ")
      if not token or token == "" then
        utils.error("API token is required")
        return
      end
      
      local default_workspace = vim.fn.input("Default Workspace (optional): ")
      
      local auth_data = {
        api_token = token,
        username = username,
        platform = "cloud",
      }
      
      if default_workspace ~= "" then
        auth_data.default_workspace = default_workspace
      end
      
      M.save_config_auth(auth_data)
      M.auth_info = {
        type = "api_token",
        token = token,
        username = username,
        platform = "cloud",
      }
      utils.info("Authentication saved successfully")
    else
      -- Use bb CLI for authentication
      utils.info("Please authenticate with 'bb auth login'")
      M.auth_info = M.get_cli_auth()
      if M.auth_info then
        local default_workspace = vim.fn.input("Default Workspace (optional): ")
        if default_workspace ~= "" then
          M.save_config_auth({
            default_workspace = default_workspace,
            platform = "cloud",
          })
        end
        utils.info("CLI authentication detected successfully")
      else
        utils.warn("CLI authentication not detected. Run 'bb auth login' manually.")
      end
    end
  else
    -- Data Center
    local base_url = vim.fn.input("Bitbucket Data Center URL: ")
    if base_url == "" then
      utils.error("Data Center URL is required")
      return
    end
    
    -- Username is required for Data Center
    local username = vim.fn.input("Username: ")
    if username == "" then
      utils.error("Username is required for Data Center authentication")
      return
    end
    
    local token = vim.fn.inputsecret("Personal Access Token: ")
    if not token or token == "" then
      utils.error("Personal access token is required")
      return
    end
    
    local default_workspace = vim.fn.input("Default Workspace (optional): ")
    
    local auth_data = {
      personal_token = token,
      username = username,
      platform = "datacenter",
      base_url = base_url,
    }
    
    if default_workspace ~= "" then
      auth_data.default_workspace = default_workspace
    end
    
    M.save_config_auth(auth_data)
    M.auth_info = {
      type = "personal_token",
      token = token,
      username = username,
      platform = "datacenter",
    }
    config.values.base_url = base_url
    utils.info("Authentication saved successfully")
  end
  
  M.platform = platform
end

-- Check if authenticated
function M.is_authenticated()
  return M.auth_info ~= nil
end

-- Get current username
function M.get_username()
  if M.auth_info then
    return M.auth_info.username
  end
  return nil
end

-- Get current user UUID
function M.get_user_uuid()
  if M.auth_info and M.auth_info.uuid then
    return M.auth_info.uuid
  end
  -- For token auth, we might not have UUID directly
  -- We could fetch it from the API if needed
  return nil
end

return M
