-- Custom statuscolumn for Bitbucket buffers (octo.nvim parity)
-- An alternative to signcolumn that handles line wrapping correctly.
-- Shows editable region markers (block start/middle/end) with dirty state.
local M = {}

--- Storage: maps bufnr -> array of {from, to, dirty}
local comments = {}

--- Add a comment range to track
--- @param bufnr number
--- @param from number 1-indexed start line
--- @param to number 1-indexed end line
--- @param dirty boolean
function M.add(bufnr, from, to, dirty)
  if not comments[bufnr] then
    comments[bufnr] = {}
  end
  table.insert(comments[bufnr], { from = from, to = to, dirty = dirty })
end

--- Remove all comment ranges for a buffer
--- @param bufnr number
function M.remove(bufnr)
  comments[bufnr] = nil
end

--- Clear all tracked ranges
function M.clear()
  comments = {}
end

--- Get the sign character and highlight for a given line.
--- Handles wrapped lines correctly using nvim_win_text_height.
--- @param buf number Buffer number
--- @param lnum number 1-indexed line number
--- @param vnum number Virtual line number (for wrapping)
--- @param win number Window ID
--- @return string sign_text The sign character(s)
--- @return string|nil hl_group The highlight group
function M.get_sign(buf, lnum, vnum, win)
  local ranges = comments[buf]
  if not ranges then
    return "  ", nil
  end

  for _, range in ipairs(ranges) do
    if lnum >= range.from and lnum <= range.to then
      local hl = range.dirty and "BitbucketDirty" or "BitbucketStatusColumn"

      -- Check if this line wraps using nvim_win_text_height
      local height = 1
      local ok, h = pcall(vim.api.nvim_win_text_height, win, { start_row = lnum - 1, end_row = lnum - 1 })
      if ok and h then
        height = h.all or 1
      end

      -- Only show the sign on the first virtual line of a wrapped line
      if vnum > 0 and vnum > 1 then
        return "  ", nil
      end

      if range.from == range.to then
        -- Single line
        return "[ ", hl
      elseif lnum == range.from then
        return "┌╴", hl
      elseif lnum == range.to then
        return "└╴", hl
      else
        return "│ ", hl
      end
    end
  end

  return "  ", nil
end

--- Statuscolumn expression function.
--- Designed to be used as vim.opt_local.statuscolumn.
--- @return string
function M.statuscolumn()
  local buf = vim.api.nvim_get_current_buf()
  local win = vim.api.nvim_get_current_win()
  local lnum = vim.v.lnum
  local vnum = vim.v.virtnum

  local sign_text, hl = M.get_sign(buf, lnum, vnum, win)

  if hl then
    return "%#" .. hl .. "#" .. sign_text .. "%*"
  end
  return sign_text
end

return M
