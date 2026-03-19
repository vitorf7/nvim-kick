local M = {}
local api = require("bitbucket.api")
local auth = require("bitbucket.auth")

-- List workspaces (Cloud) or projects (Data Center)
-- @param callback function(success, data, err)
function M.list(callback)
  if auth.platform == "cloud" then
    -- Bitbucket Cloud uses workspaces
    api.call({
      method = "GET",
      endpoint = "/workspaces",
    }, callback)
  else
    -- Bitbucket Data Center uses projects
    api.call({
      method = "GET",
      endpoint = "/projects",
    }, callback)
  end
end

-- Get a single workspace/project
-- @param opts.slug string - Workspace/project slug or key
-- @param callback function(success, data, err)
function M.get(opts, callback)
  opts = opts or {}
  
  if not opts.slug then
    callback(false, nil, "Workspace/project slug is required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/workspaces/%s", opts.slug)
  else
    endpoint = string.format("/projects/%s", opts.slug)
  end
  
  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

-- List repositories in a workspace/project
-- @param opts.workspace string|nil - For Cloud
-- @param opts.project string|nil - For Data Center
-- @param callback function(success, data, err)
function M.list_repos(opts, callback)
  opts = opts or {}
  
  local endpoint
  if auth.platform == "cloud" then
    local workspace = opts.workspace
    if not workspace then
      callback(false, nil, "Workspace is required")
      return
    end
    endpoint = string.format("/repositories/%s", workspace)
  else
    local project = opts.project
    if not project then
      callback(false, nil, "Project key is required")
      return
    end
    endpoint = string.format("/projects/%s/repos", project)
  end
  
  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

-- List members of a workspace/project
-- @param opts.slug string - Workspace/project slug or key
-- @param callback function(success, data, err)
function M.list_members(opts, callback)
  opts = opts or {}
  
  if not opts.slug then
    callback(false, nil, "Workspace/project slug is required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/workspaces/%s/members", opts.slug)
  else
    -- Data Center may not have a direct members endpoint
    callback(false, nil, "Members endpoint not available for Data Center")
    return
  end
  
  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

return M
