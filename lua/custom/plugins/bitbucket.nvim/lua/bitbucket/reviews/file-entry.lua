-- FileEntry: manages individual file diff buffers in review mode (octo.nvim parity)
local M = {}

local constants = require("bitbucket.constants")

---@class FileEntry
---@field path string
---@field old_path string|nil
---@field status string
---@field hunks table[]
---@field additions number
---@field deletions number
---@field left_bufnr number|nil
---@field right_bufnr number|nil
local FileEntry = {}
FileEntry.__index = FileEntry

function M.new(file_data)
  return setmetatable({
    path = file_data.path,
    old_path = file_data.old_path,
    status = file_data.status or "modified",
    hunks = file_data.hunks or {},
    additions = file_data.additions or 0,
    deletions = file_data.deletions or 0,
    left_bufnr = nil,
    right_bufnr = nil,
  }, FileEntry)
end

--- Load file content into left/right diff buffers.
--- @param review table The review session
function FileEntry:load_buffers(review)
  local left_buf = review.left_buf
  local right_buf = review.right_buf

  -- Clear existing extmarks
  vim.api.nvim_buf_clear_namespace(left_buf, constants.REVIEW_NS, 0, -1)
  vim.api.nvim_buf_clear_namespace(right_buf, constants.REVIEW_NS, 0, -1)

  -- Clear diff mode first
  vim.api.nvim_buf_call(left_buf, function()
    pcall(vim.cmd, "diffoff")
  end)
  vim.api.nvim_buf_call(right_buf, function()
    pcall(vim.cmd, "diffoff")
  end)

  -- Parse hunks into parallel left/right lines
  local left_lines = {}
  local right_lines = {}
  local left_signs = {}
  local right_signs = {}

  for _, hunk in ipairs(self.hunks) do
    for _, line in ipairs(hunk.lines or {}) do
      local prefix = line:sub(1, 1)
      if prefix == "-" then
        table.insert(left_lines, line:sub(2))
        table.insert(right_lines, "")
        table.insert(left_signs, #left_lines)
        table.insert(right_signs, 0)
      elseif prefix == "+" then
        table.insert(left_lines, "")
        table.insert(right_lines, line:sub(2))
        table.insert(left_signs, 0)
        table.insert(right_signs, #right_lines)
      elseif prefix == " " then
        table.insert(left_lines, line:sub(2))
        table.insert(right_lines, line:sub(2))
        table.insert(left_signs, 0)
        table.insert(right_signs, 0)
      end
    end
  end

  if #left_lines == 0 and #right_lines == 0 then
    left_lines = { "(File content unavailable)" }
    right_lines = { "(File content unavailable)" }
    left_signs = { 0 }
    right_signs = { 0 }
  end

  -- Set buffer content
  vim.api.nvim_buf_set_lines(left_buf, 0, -1, false, left_lines)
  vim.api.nvim_buf_set_lines(right_buf, 0, -1, false, right_lines)

  -- Buffer names
  pcall(vim.api.nvim_buf_set_name, left_buf,
    string.format("bitbucket://%s/%s/review/file/LEFT/%s",
      review.workspace or "", review.repo or "", self.path))
  pcall(vim.api.nvim_buf_set_name, right_buf,
    string.format("bitbucket://%s/%s/review/file/RIGHT/%s",
      review.workspace or "", review.repo or "", self.path))

  -- +/- signs via extmarks (octo-style)
  for i, line_num in ipairs(left_signs) do
    if line_num > 0 then
      vim.api.nvim_buf_set_extmark(left_buf, constants.REVIEW_NS, i - 1, 0, {
        sign_text = "-",
        sign_hl_group = "BitbucketRed",
        priority = 100,
      })
    end
  end

  for i, line_num in ipairs(right_signs) do
    if line_num > 0 then
      vim.api.nvim_buf_set_extmark(right_buf, constants.REVIEW_NS, i - 1, 0, {
        sign_text = "+",
        sign_hl_group = "BitbucketGreen",
        priority = 100,
      })
    end
  end

  -- Activate diff mode
  vim.api.nvim_buf_call(left_buf, function()
    pcall(vim.cmd, "diffthis")
  end)
  vim.api.nvim_buf_call(right_buf, function()
    pcall(vim.cmd, "diffthis")
  end)

  -- Scrollbind sync trick (octo-style)
  if vim.api.nvim_win_is_valid(review.left_win) then
    vim.api.nvim_win_call(review.left_win, function()
      pcall(vim.cmd, [[exec "normal! \<c-y>"]])
    end)
  end

  self.left_bufnr = left_buf
  self.right_bufnr = right_buf
end

--- Place thread signs on the diff buffers.
--- @param review table
--- @param threads table[] Thread metadata objects
function FileEntry:place_signs(review, threads)
  if not threads then return end

  local signs_mod = require("bitbucket.ui.signs")

  for _, thread in ipairs(threads) do
    if thread.path == self.path then
      local sign_name = thread:get_sign_name()
      local line = thread.line or 1

      -- Place on right buffer (additions side)
      if review.right_buf and vim.api.nvim_buf_is_valid(review.right_buf) then
        signs_mod.place(sign_name, review.right_buf, line)

        -- Virtual text with thread info
        vim.api.nvim_buf_set_extmark(review.right_buf, constants.REVIEW_COMMENTS_NS, line - 1, 0, {
          virt_text = { { " thread", "BitbucketCommentHeader" } },
          virt_text_pos = "eol",
        })
      end
    end
  end
end

return M
