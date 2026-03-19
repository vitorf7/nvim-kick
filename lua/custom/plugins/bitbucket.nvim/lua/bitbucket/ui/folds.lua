-- Fold management for collapsible sections (octo.nvim parity)
-- Creates manual folds for comments and review threads.
local M = {}

local config = require("bitbucket.config")

--- Create a manual fold for a range of lines.
--- @param bufnr number
--- @param start_line number 0-indexed start line
--- @param end_line number 0-indexed end line
--- @param is_opened boolean|nil Whether the fold should start open (default: true)
function M.create(bufnr, start_line, end_line, is_opened)
  if start_line >= end_line then
    return
  end

  is_opened = is_opened ~= false -- default to open

  local use_foldtext = config.values.ui and config.values.ui.use_foldtext

  -- Adjust start_line by -1 when using custom foldtext to include the header
  local fold_start = start_line
  if use_foldtext and fold_start > 0 then
    fold_start = fold_start - 1
  end

  -- Create the fold using vim commands (1-indexed)
  vim.api.nvim_buf_call(bufnr, function()
    pcall(vim.cmd, string.format("%d,%dfold", fold_start + 1, end_line + 1))
    if is_opened then
      pcall(vim.cmd, string.format("%dfoldopen", fold_start + 1))
    end
  end)
end

--- Custom foldtext function for Bitbucket buffers.
--- Extracts leading whitespace from the virtual text on the fold start line
--- to ensure proper highlight alignment when folds are closed.
--- @return string
function M.foldtext()
  local foldstart = vim.v.foldstart
  local line = vim.api.nvim_buf_get_lines(0, foldstart - 1, foldstart, false)[1] or ""

  -- Extract leading whitespace
  local indent = line:match("^(%s*)")

  -- Count folded lines
  local foldend = vim.v.foldend
  local count = foldend - foldstart + 1

  return indent .. "... (" .. count .. " lines) ..."
end

return M
