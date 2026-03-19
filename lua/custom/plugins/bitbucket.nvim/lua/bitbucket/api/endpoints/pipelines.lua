-- Pipelines API endpoints (Bitbucket Cloud only)
local M = {}

local api = require("bitbucket.api")
local auth = require("bitbucket.auth")

--- List pipelines for a repository.
--- @param opts table { workspace, repo_slug, status?, branch?, page?, pagelen? }
--- @param callback function(success, data, err)
function M.list(opts, callback)
  opts = opts or {}

  local workspace = opts.workspace or M.infer_workspace()
  local repo_slug = opts.repo_slug or opts.repo or M.infer_repo()

  if not workspace or not repo_slug then
    callback(false, nil, "Cannot determine workspace and repository")
    return
  end

  local endpoint = string.format("/repositories/%s/%s/pipelines", workspace, repo_slug)

  -- Build query params
  local params = {}
  if opts.status then
    table.insert(params, "status=" .. opts.status)
  end
  if opts.branch then
    table.insert(params, "target.branch=" .. opts.branch)
  end
  if opts.page then
    table.insert(params, "page=" .. opts.page)
  end
  if opts.pagelen then
    table.insert(params, "pagelen=" .. opts.pagelen)
  end
  -- Sort by creation date descending (most recent first)
  table.insert(params, "sort=-created_on")

  if #params > 0 then
    endpoint = endpoint .. "?" .. table.concat(params, "&")
  end

  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

--- Get a single pipeline by UUID.
--- @param opts table { workspace, repo_slug, pipeline_uuid }
--- @param callback function(success, data, err)
function M.get(opts, callback)
  opts = opts or {}

  local workspace = opts.workspace or M.infer_workspace()
  local repo_slug = opts.repo_slug or opts.repo or M.infer_repo()

  if not workspace or not repo_slug or not opts.pipeline_uuid then
    callback(false, nil, "Workspace, repository, and pipeline UUID are required")
    return
  end

  local endpoint = string.format("/repositories/%s/%s/pipelines/%s", workspace, repo_slug, opts.pipeline_uuid)

  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

--- List steps for a pipeline.
--- @param opts table { workspace, repo_slug, pipeline_uuid }
--- @param callback function(success, data, err)
function M.get_steps(opts, callback)
  opts = opts or {}

  local workspace = opts.workspace or M.infer_workspace()
  local repo_slug = opts.repo_slug or opts.repo or M.infer_repo()

  if not workspace or not repo_slug or not opts.pipeline_uuid then
    callback(false, nil, "Workspace, repository, and pipeline UUID are required")
    return
  end

  local endpoint = string.format("/repositories/%s/%s/pipelines/%s/steps", workspace, repo_slug, opts.pipeline_uuid)

  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

--- Get the log for a pipeline step.
--- @param opts table { workspace, repo_slug, pipeline_uuid, step_uuid }
--- @param callback function(success, data, err)
function M.get_step_log(opts, callback)
  opts = opts or {}

  local workspace = opts.workspace or M.infer_workspace()
  local repo_slug = opts.repo_slug or opts.repo or M.infer_repo()

  if not workspace or not repo_slug or not opts.pipeline_uuid or not opts.step_uuid then
    callback(false, nil, "Workspace, repository, pipeline UUID, and step UUID are required")
    return
  end

  local endpoint = string.format(
    "/repositories/%s/%s/pipelines/%s/steps/%s/log",
    workspace, repo_slug, opts.pipeline_uuid, opts.step_uuid
  )

  api.call({
    method = "GET",
    endpoint = endpoint,
  }, callback)
end

--- Run a pipeline.
--- @param opts table { workspace, repo_slug, target = { ref_type, ref_name, type, selector?, commit? } }
--- @param callback function(success, data, err)
function M.run(opts, callback)
  opts = opts or {}

  local workspace = opts.workspace or M.infer_workspace()
  local repo_slug = opts.repo_slug or opts.repo or M.infer_repo()

  if not workspace or not repo_slug then
    callback(false, nil, "Cannot determine workspace and repository")
    return
  end

  local endpoint = string.format("/repositories/%s/%s/pipelines", workspace, repo_slug)

  api.call({
    method = "POST",
    endpoint = endpoint,
    body = {
      target = opts.target,
    },
  }, callback)
end

--- Stop a running pipeline.
--- @param opts table { workspace, repo_slug, pipeline_uuid }
--- @param callback function(success, data, err)
function M.stop(opts, callback)
  opts = opts or {}

  local workspace = opts.workspace or M.infer_workspace()
  local repo_slug = opts.repo_slug or opts.repo or M.infer_repo()

  if not workspace or not repo_slug or not opts.pipeline_uuid then
    callback(false, nil, "Workspace, repository, and pipeline UUID are required")
    return
  end

  local endpoint = string.format("/repositories/%s/%s/pipelines/%s/stopPipeline", workspace, repo_slug, opts.pipeline_uuid)

  api.call({
    method = "POST",
    endpoint = endpoint,
  }, callback)
end

-- Helpers
function M.infer_workspace()
  local remotes = require("bitbucket.utils").get_git_info()
  if not remotes then return nil end
  for _, remote in ipairs(remotes) do
    local ws = remote.url:match("bitbucket%.org/([^/]+)/")
    if ws then return ws end
  end
  return nil
end

function M.infer_repo()
  local remotes = require("bitbucket.utils").get_git_info()
  if not remotes then return nil end
  for _, remote in ipairs(remotes) do
    local repo = remote.url:match("bitbucket%.org/[^/]+/([^/%.]+)")
    if repo then return repo end
  end
  return nil
end

return M
