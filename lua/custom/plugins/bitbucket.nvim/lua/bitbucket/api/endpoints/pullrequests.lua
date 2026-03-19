local M = {}
local api = require("bitbucket.api")
local auth = require("bitbucket.auth")

-- List pull requests
-- @param opts.workspace string|nil - Workspace/project key (optional, inferred from git if nil)
-- @param opts.repo string|nil - Repository slug (optional, inferred from git if nil)
-- @param opts.state string|nil - "OPEN", "MERGED", "DECLINED", "SUPERSEDED"
-- @param callback function(success, data, err)
function M.list(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo then
    callback(false, nil, "Cannot determine workspace and repository")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests", workspace, repo)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests", workspace, repo)
  end
  
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

-- Get a single pull request
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number - Pull request ID
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
    callback(false, nil, "Pull request ID is required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d", workspace, repo, opts.id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d", workspace, repo, opts.id)
  end
  
  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

-- Create a pull request
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.title string
-- @param opts.source_branch string
-- @param opts.destination_branch string|nil - Defaults to repo's main branch
-- @param opts.description string|nil
-- @param opts.close_source_branch boolean|nil
-- @param callback function(success, data, err)
function M.create(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo then
    callback(false, nil, "Cannot determine workspace and repository")
    return
  end
  
  if not opts.title or not opts.source_branch then
    callback(false, nil, "Title and source branch are required")
    return
  end
  
  local endpoint
  local body
  
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests", workspace, repo)
    body = {
      title = opts.title,
      source = {
        branch = { name = opts.source_branch },
      },
    }
    
    if opts.destination_branch then
      body.destination = {
        branch = { name = opts.destination_branch },
      }
    end
    
    if opts.description then
      body.description = opts.description
    end
    
    if opts.close_source_branch ~= nil then
      body.close_source_branch = opts.close_source_branch
    end
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests", workspace, repo)
    body = {
      title = opts.title,
      fromRef = {
        id = "refs/heads/" .. opts.source_branch,
      },
    }
    
    if opts.destination_branch then
      body.toRef = {
        id = "refs/heads/" .. opts.destination_branch,
      }
    end
    
    if opts.description then
      body.description = opts.description
    end
  end
  
  api.call({
    method = "POST",
    endpoint = endpoint,
    body = body,
  }, callback)
end

-- Update a pull request
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number
-- @param opts.title string|nil
-- @param opts.description string|nil
-- @param opts.state string|nil - "OPEN", "DECLINED"
-- @param callback function(success, data, err)
function M.update(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id then
    callback(false, nil, "Workspace, repository, and ID are required")
    return
  end
  
  local endpoint
  local body = {}
  
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d", workspace, repo, opts.id)
    
    if opts.title then
      body.title = opts.title
    end
    if opts.description then
      body.description = opts.description
    end
    if opts.state then
      body.state = opts.state
    end
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d", workspace, repo, opts.id)
    
    if opts.title then
      body.title = opts.title
    end
    if opts.description then
      body.description = opts.description
    end
    if opts.state then
      body.state = opts.state
    end
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

-- Approve a pull request
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number
-- @param callback function(success, data, err)
function M.approve(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id then
    callback(false, nil, "Workspace, repository, and ID are required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/approve", workspace, repo, opts.id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/approve", workspace, repo, opts.id)
  end
  
  api.call({
    method = "POST",
    endpoint = endpoint,
  }, callback)
end

-- Unapprove a pull request
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number
-- @param callback function(success, data, err)
function M.unapprove(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id then
    callback(false, nil, "Workspace, repository, and ID are required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/approve", workspace, repo, opts.id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/approve", workspace, repo, opts.id)
  end
  
  api.call({
    method = "DELETE",
    endpoint = endpoint,
  }, callback)
end

-- Merge a pull request
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number
-- @param opts.merge_strategy string|nil - "merge", "squash", "fast_forward"
-- @param opts.close_source_branch boolean|nil
-- @param callback function(success, data, err)
function M.merge(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id then
    callback(false, nil, "Workspace, repository, and ID are required")
    return
  end
  
  local endpoint
  local body = {}
  
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/merge", workspace, repo, opts.id)
    
    if opts.merge_strategy then
      body.merge_strategy = opts.merge_strategy
    end
    if opts.close_source_branch ~= nil then
      body.close_source_branch = opts.close_source_branch
    end
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/merge", workspace, repo, opts.id)
    
    if opts.merge_strategy then
      body.strategy = opts.merge_strategy
    end
  end
  
  api.call({
    method = "POST",
    endpoint = endpoint,
    body = vim.tbl_isempty(body) and nil or body,
  }, callback)
end

-- Decline (close) a pull request
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number
-- @param callback function(success, data, err)
function M.decline(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id then
    callback(false, nil, "Workspace, repository, and ID are required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/decline", workspace, repo, opts.id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/decline", workspace, repo, opts.id)
  end
  
  api.call({
    method = "POST",
    endpoint = endpoint,
  }, callback)
end

-- Get pull request diff
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number
-- @param callback function(success, data, err)
function M.get_diff(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id then
    callback(false, nil, "Workspace, repository, and ID are required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/diff", workspace, repo, opts.id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/diff", workspace, repo, opts.id)
  end
  
  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

-- Get pull request commits
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number
-- @param callback function(success, data, err)
function M.get_commits(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id then
    callback(false, nil, "Workspace, repository, and ID are required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/commits", workspace, repo, opts.id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/commits", workspace, repo, opts.id)
  end
  
  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

-- Helper: Infer workspace from git remote
function M.infer_workspace()
  local remotes = require("bitbucket.utils").get_git_info()
  if not remotes then
    return nil
  end
  
  for _, remote in ipairs(remotes) do
    -- Parse bitbucket.org URLs: https://bitbucket.org/workspace/repo.git
    local workspace = remote.url:match("bitbucket%.org/([^/]+)/")
    if workspace then
      return workspace
    end
    
    -- Parse Data Center URLs: https://host/projects/PROJECT/repos/repo
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
    -- Parse bitbucket.org URLs
    local repo = remote.url:match("bitbucket%.org/[^/]+/([^/%.]+)")
    if repo then
      return repo
    end
    
    -- Parse Data Center URLs
    local dc_repo = remote.url:match("/repos/([^/]+)")
    if dc_repo then
      return dc_repo
    end
  end
  
  return nil
end

return M
