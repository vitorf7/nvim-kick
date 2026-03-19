-- File Panel: the changed files list in the review layout (octo.nvim parity)
local M = {}

local constants = require("bitbucket.constants")
local config = require("bitbucket.config")
local renderer = require("bitbucket.reviews.renderer")
local bubbles = require("bitbucket.ui.bubbles")

---@class FilePanel
---@field bufnr number
---@field winnr number
---@field review table The parent review session
local FilePanel = {}
FilePanel.__index = FilePanel

function M.new(bufnr, winnr, review)
  return setmetatable({
    bufnr = bufnr,
    winnr = winnr,
    review = review,
  }, FilePanel)
end

--- Render the full file panel with octo-style formatting.
function FilePanel:render()
  local review = self.review
  local data = renderer.RenderData()

  -- Calculate totals
  local total_additions = 0
  local total_deletions = 0
  for _, file in ipairs(review.files or {}) do
    total_additions = total_additions + (file.additions or 0)
    total_deletions = total_deletions + (file.deletions or 0)
  end

  -- Header: PR title
  data:add_line(string.format("PR #%d: %s", review.pr.id or 0, review.pr.title or ""))
  data:add_hl("BitbucketFilePanelTitle", 0, 0, -1)

  -- Counter line: "Files changed (N)"
  local counter_text = string.format("Files changed (%d)", #(review.files or {}))
  data:add_line(counter_text)
  data:add_hl("BitbucketFilePanelCounter", 1, 0, -1)

  -- Blank separator
  data:add_line("")

  -- File list
  local use_icons = config.values.file_panel and config.values.file_panel.use_icons

  for i, file in ipairs(review.files or {}) do
    local line_idx = i + 2 -- account for header lines

    -- Status letter
    local status_char = "M"
    if file.status == "added" then status_char = "A"
    elseif file.status == "removed" then status_char = "D"
    elseif file.status == "renamed" then status_char = "R"
    end

    -- Viewed indicator
    local viewed = review.viewed_files and review.viewed_files[file.path] and "✓" or "○"

    -- Current file indicator
    local current = (review.current_file == i) and "> " or "  "

    -- File icon
    local icon = ""
    local icon_hl = nil
    if use_icons then
      local ext = file.path:match("%.([^%.]+)$")
      local fname = file.path:match("([^/]+)$") or file.path
      icon, icon_hl = renderer.get_file_icon(fname, ext)
      icon = icon .. " "
    end

    -- Diffstat histogram (5 blocks)
    local histogram = ""
    local file_total = (file.additions or 0) + (file.deletions or 0)
    if file_total > 0 then
      local width = 5
      local add_blocks = math.floor((file.additions or 0) / file_total * width + 0.5)
      local del_blocks = width - add_blocks
      histogram = string.rep("■", add_blocks) .. string.rep("■", del_blocks)
    end

    -- Path (truncated)
    local path_display = file.path
    if #path_display > 30 then
      path_display = "..." .. path_display:sub(-27)
    end

    -- Format: > ✓ ■■■■□ A  file.lua
    local line_text = string.format("%s%s %s %s %s%s",
      current, viewed, histogram, status_char, icon, path_display)
    data:add_line(line_text)

    -- Highlights
    -- Status char
    local status_hl = renderer.get_git_hl(file.status or "M")
    local status_col = #current + #viewed + 1 + #histogram + 1
    data:add_hl(status_hl, line_idx, status_col, status_col + 1)

    -- Histogram coloring
    if file_total > 0 then
      local hist_start = #current + #viewed + 1
      local width = 5
      local add_blocks = math.floor((file.additions or 0) / file_total * width + 0.5)
      if add_blocks > 0 then
        data:add_hl("BitbucketDiffstatAdditions", line_idx, hist_start, hist_start + add_blocks)
      end
      if add_blocks < width then
        data:add_hl("BitbucketDiffstatDeletions", line_idx, hist_start + add_blocks, hist_start + width)
      end
    end

    -- Current file highlight
    if review.current_file == i then
      data:add_hl("BitbucketFilePanelSelected", line_idx, 0, -1)
    end

    -- Viewed checkmark color
    if review.viewed_files and review.viewed_files[file.path] then
      data:add_hl("BitbucketGreen", line_idx, #current, #current + #viewed)
    end
  end

  -- Footer
  data:add_line("")
  data:add_line(string.rep("─", 40))

  -- Commit range info
  local footer_line = "Showing changes"
  if review.pr.source and review.pr.destination then
    footer_line = string.format("Showing changes: %s...%s",
      review.pr.destination.branch and review.pr.destination.branch.name or "?",
      review.pr.source.branch and review.pr.source.branch.name or "?")
  end
  data:add_line(footer_line)

  -- Render to buffer
  renderer.render(self.bufnr, data, constants.FILE_PANEL_NS)
end

--- Highlight the currently selected file.
function FilePanel:highlight_file(file_index)
  if not file_index then return end

  local ns = constants.FILE_PANEL_NS
  -- Clear existing selection highlight
  local line_idx = file_index + 2
  vim.api.nvim_buf_set_extmark(self.bufnr, ns, line_idx, 0, {
    end_line = line_idx,
    end_col = -1,
    hl_group = "BitbucketFilePanelSelected",
    priority = 200,
  })
end

return M
