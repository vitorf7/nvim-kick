local M = {}
local api = require("bitbucket.api")
local auth = require("bitbucket.auth")

-- Note: Bitbucket Cloud and Data Center have different issue implementations
-- This endpoint assumes Bitbucket Cloud issues (not available in all workspaces)

-- List issues
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.state string|nil - "new", "open", "resolved", "closed", etc.
-- @param callback function(success, data, err)
function M.list(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo then
    callback(false, nil, "Cannot determine workspace and repository")
    return
  end
  
  if auth.platform ~= "cloud" then
    callback(false, nil, "Issues API only available for Bitbucket Cloud")
    return
  end
  
  local endpoint = string.format("/repositories/%s/%s/issues", workspace, repo)
  
  local params = {}
  if opts.state then
    params.state = opts.state
  end
  
  api.call({
    method = "GET",
    endpoint = endpoint,
    params = params,
  }, callback)
end

-- Get a single issue
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number - Issue ID
-- @param callback function(success, data, err)
function M.get(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo then
    callback(false, nil, "Cannot determine workspace and repository")
    return
  end
  
  if not opts.id then
    callback(false, nil, "Issue ID is required")
    return
  end
  
  if auth.platform ~= "cloud" then
    callback(false, nil, "Issues API only available for Bitbucket Cloud")
    return
  end
  
  local endpoint = string.format("/repositories/%s/%s/issues/%d", workspace, repo, opts.id)
  
  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

-- Create an issue
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.title string
-- @param opts.content string|nil
-- @param opts.kind string|nil - "bug", "enhancement", "proposal", "task"
-- @param opts.priority string|nil - "trivial", "minor", "major", "critical", "blocker"
-- @param callback function(success, data, err)
function M.create(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo then
    callback(false, nil, "Cannot determine workspace and repository")
    return
  end
  
  if not opts.title then
    callback(false, nil, "Issue title is required")
    return
  end
  
  if auth.platform ~= "cloud" then
    callback(false, nil, "Issues API only available for Bitbucket Cloud")
    return
  end
  
  local endpoint = string.format("/repositories/%s/%s/issues", workspace, repo)
  
  local body = {
    title = opts.title,
  }
  
  if opts.content then
    body.content = {
      raw = opts.content,
    }
  end
  
  if opts.kind then
    body.kind = opts.kind
  end
  
  if opts.priority then
    body.priority = opts.priority
  end
  
  api.call({
    method = "POST",
    endpoint = endpoint,
    body = body,
  }, callback)
end

-- Update an issue
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number
-- @param opts.title string|nil
-- @param opts.content string|nil
-- @param opts.state string|nil - "new", "open", "resolved", "closed", etc.
-- @param callback function(success, data, err)
function M.update(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id then
    callback(false, nil, "Workspace, repository, and ID are required")
    return
  end
  
  if auth.platform ~= "cloud" then
    callback(false, nil, "Issues API only available for Bitbucket Cloud")
    return
  end
  
  local endpoint = string.format("/repositories/%s/%s/issues/%d", workspace, repo, opts.id)
  
  local body = {}
  
  if opts.title then
    body.title = opts.title
  end
  
  if opts.content then
    body.content = {
      raw = opts.content,
    }
  end
  
  if opts.state then
    body.state = opts.state
  end
  
  if vim.tbl_isempty(body) then
    callback(false, nil, "No fields to update")
    return
  end
  
  api.call({
    method = "PUT",
    endpoint = endpoint,
    body = body,
  }, callback)
end

-- Helper: Infer workspace from git remote
function M.infer_workspace()
  local remotes = require("bitbucket.utils").get_git_info()
  if not remotes then
    return nil
  end
  
  for _, remote in ipairs(remotes) do
    local workspace = remote.url:match("bitbucket%.org/([^/]+)/")
    if workspace then
      return workspace
    end
    
    local project = remote.url:match("/projects/([^/]+)/")
    if project then
      return project
    end
  end
  
  return nil
end

-- Helper: Infer repo from git remote
function M.infer_repo()
  local remotes = require("bitbucket.utils").get_git_info()
  if not remotes then
    return nil
  end
  
  for _, remote in ipairs(remotes) do
    local repo = remote.url:match("bitbucket%.org/[^/]+/([^/%.]+)")
    if repo then
      return repo
    end
    
    local dc_repo = remote.url:match("/repos/([^/]+)")
    if dc_repo then
      return dc_repo
    end
  end
  
  return nil
end

return M
