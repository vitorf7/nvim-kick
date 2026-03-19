local M = {}
local constants = require("bitbucket.constants")
local config = require("bitbucket.config")

-- Sign definitions (octo-style)
local comment_icon = (config.values and config.values.comment_icon) or (config.values.icons and config.values.icons.comment) or "▎"
local signs = {
  -- Thread indicators (comment markers)
  thread = { text = comment_icon, hl = "BitbucketBlue" },
  thread_resolved = { text = comment_icon, hl = "BitbucketGreen" },
  thread_outdated = { text = comment_icon, hl = "BitbucketRed" },
  thread_pending = { text = comment_icon, hl = "BitbucketYellow" },
  thread_resolved_pending = { text = comment_icon, hl = "BitbucketYellow" },
  thread_outdated_pending = { text = comment_icon, hl = "BitbucketYellow" },

  -- Comment range
  comment_range = { text = "", hl = "BitbucketGreen", numhl = "BitbucketGreen" },

  -- Review markers
  review_comment = { text = "▎", hl = "BitbucketReviewComment" },
  review_thread = { text = "", hl = "BitbucketReviewThread" },

  -- File status in diff view
  file_added = { text = "+", hl = "BitbucketGreen" },
  file_removed = { text = "-", hl = "BitbucketRed" },
  file_modified = { text = "~", hl = "BitbucketBlue" },
  file_renamed = { text = "→", hl = "BitbucketBlue" },

  -- UI markers
  viewed = { text = "✓", hl = "BitbucketFilePanelViewed" },
  unviewed = { text = "○", hl = "BitbucketFilePanelPath" },
  selected = { text = ">", hl = "BitbucketFilePanelSelected" },

  -- Editable block indicators (octo-style)
  clean_block_start = { text = "┌", linehl = "BitbucketEditable" },
  clean_block_end = { text = "└", linehl = "BitbucketEditable" },
  clean_block_middle = { text = "│", linehl = "BitbucketEditable" },
  dirty_block_start = { text = "┌", texthl = "BitbucketRed", linehl = "BitbucketEditable" },
  dirty_block_end = { text = "└", texthl = "BitbucketRed", linehl = "BitbucketEditable" },
  dirty_block_middle = { text = "│", texthl = "BitbucketRed", linehl = "BitbucketEditable" },
}

-- Setup signs (octo.nvim style)
function M.setup()
  for name, sign in pairs(signs) do
    local sign_name = "Bitbucket" .. M.capitalize(name)
    local sign_def = {
      text = sign.text,
      texthl = sign.hl,
      numhl = sign.numhl or "",
      linehl = sign.linehl or "",
    }
    vim.fn.sign_define(sign_name, sign_def)
  end
end

-- Place a sign
function M.place(name, bufnr, lnum)
  local sign_name = "Bitbucket" .. M.capitalize(name)
  vim.fn.sign_place(0, "bitbucket_signs", sign_name, bufnr, { lnum = lnum, priority = 10 })
end

-- Place a sign with specific id (for tracking)
function M.place_with_id(name, bufnr, lnum, sign_id)
  local sign_name = "Bitbucket" .. M.capitalize(name)
  return vim.fn.sign_place(sign_id, "bitbucket_signs", sign_name, bufnr, { lnum = lnum, priority = 10 })
end

-- Unplace all signs from a buffer
function M.unplace_all(bufnr)
  vim.fn.sign_unplace("bitbucket_signs", { buffer = bufnr })
end

--- Place editable region signs (clean or dirty block markers).
--- Handles both signcolumn and statuscolumn modes.
--- @param bufnr number
--- @param start_line number 0-indexed
--- @param end_line number 0-indexed
--- @param is_dirty boolean
function M.place_signs(bufnr, start_line, end_line, is_dirty)
  local ui_config = config.values and config.values.ui or {}

  if ui_config.use_statuscolumn then
    local statuscolumn = require("bitbucket.ui.statuscolumn")
    statuscolumn.add(bufnr, start_line + 1, end_line + 1, is_dirty)
    return
  end

  -- Signcolumn mode
  if start_line == end_line then
    local sign = is_dirty and "dirty_block_middle" or "clean_block_middle"
    M.place(sign, bufnr, start_line + 1)
  else
    local prefix = is_dirty and "dirty" or "clean"
    M.place(prefix .. "_block_start", bufnr, start_line + 1)
    for l = start_line + 1, end_line - 1 do
      M.place(prefix .. "_block_middle", bufnr, l + 1)
    end
    M.place(prefix .. "_block_end", bufnr, end_line + 1)
  end
end

-- Unplace specific sign from a buffer
function M.unplace(name, bufnr)
  vim.fn.sign_unplace("bitbucket_signs", { buffer = bufnr, id = name })
end

-- Add extmark for inline highlighting (octo-style with more options)
function M.add_highlight(bufnr, line, col, opts)
  opts = opts or {}
  local ns_id = opts.ns_id or constants.HIGHLIGHT_NS

  local extmark_opts = {
    end_line = opts.end_line or line,
    end_col = opts.end_col,
    hl_group = opts.hl_group,
    hl_eol = opts.hl_eol or false,
    priority = opts.priority or 10,
  }

  if opts.virt_text then
    extmark_opts.virt_text = opts.virt_text
    extmark_opts.virt_text_pos = opts.virt_text_pos or "eol"
    extmark_opts.virt_text_hide = opts.virt_text_hide or false
  end

  if opts.virt_lines then
    extmark_opts.virt_lines = opts.virt_lines
    extmark_opts.virt_lines_above = opts.virt_lines_above or false
  end

  if opts.sign_text then
    extmark_opts.sign_text = opts.sign_text
    extmark_opts.sign_hl_group = opts.sign_hl_group
  end

  if opts.number_hl_group then
    extmark_opts.number_hl_group = opts.number_hl_group
  end

  if opts.line_hl_group then
    extmark_opts.line_hl_group = opts.line_hl_group
  end

  if opts.conceal then
    extmark_opts.conceal = opts.conceal
  end

  if opts.spell then
    extmark_opts.spell = opts.spell
  end

  return vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, col or 0, extmark_opts)
end

-- Add virtual text (octo-style)
function M.add_virtual_text(bufnr, line, chunks, opts)
  opts = opts or {}
  local ns_id = opts.ns_id or constants.VIRTUAL_TEXT_NS

  local extmark_opts = {
    virt_text = chunks,
    virt_text_pos = opts.pos or "eol",
    virt_text_hide = opts.hide or false,
    priority = opts.priority or 10,
  }

  if opts.hl_mode then
    extmark_opts.hl_mode = opts.hl_mode
  end

  return vim.api.nvim_buf_set_extmark(bufnr, ns_id, line, 0, extmark_opts)
end

-- Clear all extmarks from buffer
function M.clear_highlights(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, constants.HIGHLIGHT_NS, 0, -1)
  vim.api.nvim_buf_clear_namespace(bufnr, constants.COMMENT_NS, 0, -1)
  vim.api.nvim_buf_clear_namespace(bufnr, constants.REVIEW_NS, 0, -1)
  vim.api.nvim_buf_clear_namespace(bufnr, constants.VIRTUAL_TEXT_NS, 0, -1)
end

-- Clear specific namespace
function M.clear_namespace(bufnr, ns_id)
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
end

-- Helper: Capitalize first letter
function M.capitalize(str)
  return str:gsub("^%l", string.upper)
end

-- Get sign id at line
function M.get_signs_at_line(bufnr, lnum)
  return vim.fn.sign_getplaced(bufnr, { group = "bitbucket_signs", lnum = lnum })
end

return M
