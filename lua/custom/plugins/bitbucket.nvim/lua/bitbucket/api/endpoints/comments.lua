local M = {}
local api = require("bitbucket.api")
local auth = require("bitbucket.auth")

-- List pull request comments
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number - Pull request ID
-- @param callback function(success, data, err)
function M.list(opts, callback)
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
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/comments", workspace, repo, opts.id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/comments", workspace, repo, opts.id)
  end
  
  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

-- Get a single comment
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number - Pull request ID
-- @param opts.comment_id number
-- @param callback function(success, data, err)
function M.get(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id or not opts.comment_id then
    callback(false, nil, "Workspace, repository, PR ID, and comment ID are required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/comments/%d", workspace, repo, opts.id, opts.comment_id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/comments/%d", workspace, repo, opts.id, opts.comment_id)
  end
  
  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

-- Create a comment
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number - Pull request ID
-- @param opts.content string - Comment text (raw markdown)
-- @param opts.inline table|nil - Inline comment { path = "...", line_from = N, line_to = N }
-- @param callback function(success, data, err)
function M.create(opts, callback)
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
  
  if not opts.content then
    callback(false, nil, "Comment content is required")
    return
  end
  
  local endpoint
  local body
  
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/comments", workspace, repo, opts.id)
    body = {
      content = {
        raw = opts.content,
      },
    }
    
    if opts.inline then
      body.inline = {
        path = opts.inline.path,
        from = opts.inline.line_from,
        to = opts.inline.line_to,
      }
    end
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/comments", workspace, repo, opts.id)
    body = {
      text = opts.content,
    }
    
    if opts.inline then
      body.anchor = {
        path = opts.inline.path,
        line = opts.inline.line_from,
        lineType = "ADDED",
      }
    end
  end
  
  api.call({
    method = "POST",
    endpoint = endpoint,
    body = body,
  }, callback)
end

-- Update a comment
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number - Pull request ID
-- @param opts.comment_id number
-- @param opts.content string - New comment text
-- @param callback function(success, data, err)
function M.update(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id or not opts.comment_id then
    callback(false, nil, "Workspace, repository, PR ID, and comment ID are required")
    return
  end
  
  if not opts.content then
    callback(false, nil, "Comment content is required")
    return
  end
  
  local endpoint
  local body
  
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/comments/%d", workspace, repo, opts.id, opts.comment_id)
    body = {
      content = {
        raw = opts.content,
      },
    }
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/comments/%d", workspace, repo, opts.id, opts.comment_id)
    body = {
      text = opts.content,
    }
  end
  
  api.call({
    method = "PUT",
    endpoint = endpoint,
    body = body,
  }, callback)
end

-- Delete a comment
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number - Pull request ID
-- @param opts.comment_id number
-- @param callback function(success, data, err)
function M.delete(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id or not opts.comment_id then
    callback(false, nil, "Workspace, repository, PR ID, and comment ID are required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/comments/%d", workspace, repo, opts.id, opts.comment_id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/comments/%d", workspace, repo, opts.id, opts.comment_id)
  end
  
  api.call({
    method = "DELETE",
    endpoint = endpoint,
  }, callback)
end

-- Resolve a comment thread
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number - Pull request ID
-- @param opts.comment_id number
-- @param callback function(success, data, err)
function M.resolve(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id or not opts.comment_id then
    callback(false, nil, "Workspace, repository, PR ID, and comment ID are required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/comments/%d/resolve", workspace, repo, opts.id, opts.comment_id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/comments/%d/resolve", workspace, repo, opts.id, opts.comment_id)
  end
  
  api.call({
    method = "POST",
    endpoint = endpoint,
  }, callback)
end

-- Unresolve a comment thread
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number - Pull request ID
-- @param opts.comment_id number
-- @param callback function(success, data, err)
function M.unresolve(opts, callback)
  opts = opts or {}
  
  local workspace = opts.workspace or M.infer_workspace()
  local repo = opts.repo or M.infer_repo()
  
  if not workspace or not repo or not opts.id or not opts.comment_id then
    callback(false, nil, "Workspace, repository, PR ID, and comment ID are required")
    return
  end
  
  local endpoint
  if auth.platform == "cloud" then
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/comments/%d/resolve", workspace, repo, opts.id, opts.comment_id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/comments/%d/resolve", workspace, repo, opts.id, opts.comment_id)
  end
  
  api.call({
    method = "DELETE",
    endpoint = endpoint,
  }, callback)
end

-- Get pull request activity (includes comments and other activities)
-- @param opts.workspace string|nil
-- @param opts.repo string|nil
-- @param opts.id number - Pull request ID
-- @param callback function(success, data, err)
function M.get_activity(opts, callback)
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
    endpoint = string.format("/repositories/%s/%s/pullrequests/%d/activity", workspace, repo, opts.id)
  else
    endpoint = string.format("/projects/%s/repos/%s/pull-requests/%d/activities", workspace, repo, opts.id)
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
