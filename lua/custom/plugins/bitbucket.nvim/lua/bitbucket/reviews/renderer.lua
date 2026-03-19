-- Generic render engine for file panel and other review UI (octo.nvim parity)
local M = {}

---@class RenderData
---@field lines string[] Buffer lines
---@field hl table[] Highlight data: { group, line_idx, first, last }
local RenderData = {}
RenderData.__index = RenderData

function M.RenderData()
  return setmetatable({
    lines = {},
    hl = {},
  }, RenderData)
end

function RenderData:add_line(line)
  table.insert(self.lines, line)
end

function RenderData:add_hl(group, line_idx, first, last)
  table.insert(self.hl, {
    group = group,
    line_idx = line_idx,
    first = first,
    last = last,
  })
end

--- Render data to a buffer: set lines, clear namespace, apply highlights.
--- @param bufnr number
--- @param data RenderData
--- @param ns number|nil Namespace (defaults to FILE_PANEL_NS)
function M.render(bufnr, data, ns)
  local constants = require("bitbucket.constants")
  ns = ns or constants.FILE_PANEL_NS

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, data.lines)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  for _, hl in ipairs(data.hl) do
    local end_col = hl.last
    if end_col == -1 then
      end_col = #data.lines[hl.line_idx + 1]
    end
    vim.api.nvim_buf_set_extmark(bufnr, ns, hl.line_idx, hl.first, {
      end_col = end_col,
      hl_group = hl.group,
    })
  end
end

--- Get a file icon using nvim-web-devicons (if available).
--- @param name string File name
--- @param ext string|nil File extension
--- @return string icon
--- @return string|nil hl_group
function M.get_file_icon(name, ext)
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok then
    local icon, hl = devicons.get_icon(name, ext, { default = true })
    return icon or "", hl
  end
  return "", nil
end

--- Map a git status letter to a highlight group.
--- @param status string One of: A, M, R, C, T, U, X, D, B
--- @return string highlight group name
function M.get_git_hl(status)
  local map = {
    A = "BitbucketStatusAdded",
    M = "BitbucketStatusModified",
    R = "BitbucketStatusRenamed",
    C = "BitbucketStatusCopied",
    T = "BitbucketStatusModified",
    U = "BitbucketStatusUnmerged",
    X = "BitbucketStatusModified",
    D = "BitbucketStatusDeleted",
    B = "BitbucketStatusModified",
    added = "BitbucketStatusAdded",
    modified = "BitbucketStatusModified",
    removed = "BitbucketStatusDeleted",
    renamed = "BitbucketStatusRenamed",
  }
  return map[status] or "BitbucketStatusModified"
end

return M
