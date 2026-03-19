-- TitleMetadata: tracks the title editable region in a Bitbucket buffer (octo.nvim parity)
local M = {}

---@class TitleMetadata
---@field savedBody string The original title text from the API
---@field body string The current title text in the buffer
---@field dirty boolean Whether the title has been modified
---@field extmark number|nil The extmark ID tracking this region
---@field startLine number 0-indexed start line
---@field endLine number 0-indexed end line
local TitleMetadata = {}
TitleMetadata.__index = TitleMetadata

function M.new(opts)
  opts = opts or {}
  return setmetatable({
    savedBody = opts.savedBody or "",
    body = opts.body or opts.savedBody or "",
    dirty = false,
    extmark = opts.extmark,
    startLine = opts.startLine or 0,
    endLine = opts.endLine or 0,
  }, TitleMetadata)
end

function TitleMetadata:is_dirty()
  return vim.trim(self.body) ~= vim.trim(self.savedBody)
end

function TitleMetadata:mark_saved()
  self.savedBody = self.body
  self.dirty = false
end

return M
