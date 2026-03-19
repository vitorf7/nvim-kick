-- ThreadMetadata: tracks a review thread in a buffer (octo.nvim parity)
local M = {}

---@class ThreadMetadata
---@field threadId number|string The thread/comment ID
---@field replyTo number|nil Parent comment ID for replies
---@field path string File path this thread is on
---@field line number The line number in the file
---@field side string|nil "LEFT"|"RIGHT"
---@field resolved boolean Whether the thread is resolved
---@field outdated boolean Whether the thread is outdated
local ThreadMetadata = {}
ThreadMetadata.__index = ThreadMetadata

function M.new(opts)
  opts = opts or {}
  return setmetatable({
    threadId = opts.threadId,
    replyTo = opts.replyTo,
    path = opts.path or "",
    line = opts.line or 0,
    side = opts.side,
    resolved = opts.resolved or false,
    outdated = opts.outdated or false,
  }, ThreadMetadata)
end

function ThreadMetadata:get_sign_name()
  if self.resolved then
    return "thread_resolved"
  elseif self.outdated then
    return "thread_outdated"
  else
    return "thread"
  end
end

return M
