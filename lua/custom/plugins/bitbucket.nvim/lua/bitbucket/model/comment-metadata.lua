-- CommentMetadata: tracks a comment editable region (octo.nvim parity)
local M = {}

---@class CommentMetadata
---@field id number|string The comment ID from the API
---@field author table The comment author { display_name, uuid, ... }
---@field savedBody string The original comment text from the API
---@field body string The current comment text in the buffer
---@field dirty boolean Whether the comment has been modified
---@field extmark number|nil The extmark ID tracking this region
---@field namespace number The extmark namespace ID for this comment's header
---@field viewerCanUpdate boolean Whether the current user can edit
---@field viewerCanDelete boolean Whether the current user can delete
---@field viewerDidAuthor boolean Whether the current user authored this comment
---@field kind string Comment kind: "PullRequestComment"|"PullRequestReviewComment"|"CommentReply"
---@field replyTo number|nil Parent comment ID (for replies)
---@field path string|nil File path (for inline comments)
---@field diffSide string|nil "LEFT"|"RIGHT" (for inline comments)
---@field snippetStartLine number|nil Start line of diff snippet
---@field snippetEndLine number|nil End line of diff snippet
---@field startLine number 0-indexed buffer start line
---@field endLine number 0-indexed buffer end line
local CommentMetadata = {}
CommentMetadata.__index = CommentMetadata

function M.new(opts)
  opts = opts or {}
  return setmetatable({
    id = opts.id,
    author = opts.author or {},
    savedBody = opts.savedBody or "",
    body = opts.body or opts.savedBody or "",
    dirty = false,
    extmark = opts.extmark,
    namespace = opts.namespace,
    viewerCanUpdate = opts.viewerCanUpdate or false,
    viewerCanDelete = opts.viewerCanDelete or false,
    viewerDidAuthor = opts.viewerDidAuthor or false,
    kind = opts.kind or "PullRequestComment",
    replyTo = opts.replyTo,
    path = opts.path,
    diffSide = opts.diffSide,
    snippetStartLine = opts.snippetStartLine,
    snippetEndLine = opts.snippetEndLine,
    startLine = opts.startLine or 0,
    endLine = opts.endLine or 0,
  }, CommentMetadata)
end

function CommentMetadata:is_dirty()
  return vim.trim(self.body) ~= vim.trim(self.savedBody)
end

function CommentMetadata:mark_saved()
  self.savedBody = self.body
  self.dirty = false
end

function CommentMetadata:is_inline()
  return self.path ~= nil
end

return M
