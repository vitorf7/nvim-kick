-- BodyMetadata: tracks the body/description editable region (octo.nvim parity)
local M = {}

---@class BodyMetadata
---@field savedBody string The original body text from the API
---@field body string The current body text in the buffer
---@field dirty boolean Whether the body has been modified
---@field extmark number|nil The extmark ID tracking this region
---@field startLine number 0-indexed start line
---@field endLine number 0-indexed end line
---@field viewerCanUpdate boolean Whether the current user can edit
local BodyMetadata = {}
BodyMetadata.__index = BodyMetadata

function M.new(opts)
  opts = opts or {}
  return setmetatable({
    savedBody = opts.savedBody or "",
    body = opts.body or opts.savedBody or "",
    dirty = false,
    extmark = opts.extmark,
    startLine = opts.startLine or 0,
    endLine = opts.endLine or 0,
    viewerCanUpdate = opts.viewerCanUpdate ~= false,
  }, BodyMetadata)
end

function BodyMetadata:is_dirty()
  return vim.trim(self.body) ~= vim.trim(self.savedBody)
end

function BodyMetadata:mark_saved()
  self.savedBody = self.body
  self.dirty = false
end

return M
