-- Thread Panel: auto-show review threads on CursorHold (octo.nvim parity)
local M = {}

local constants = require("bitbucket.constants")
local config = require("bitbucket.config")
local writers = require("bitbucket.ui.writers")

--- Show review threads at the current cursor line.
--- Called from CursorHold autocmd during review.
--- @param review table The active review session
--- @param jump_to_buffer boolean|nil Whether to jump to the thread buffer
function M.show_review_threads(review, jump_to_buffer)
  if not review or not review.existing_comments then
    return
  end

  -- Check config
  local auto_show = config.values.reviews and config.values.reviews.auto_show_threads
  if not auto_show and not jump_to_buffer then
    return
  end

  -- Get current cursor position
  local win = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_win_get_buf(win)
  local cursor = vim.api.nvim_win_get_cursor(win)
  local cursor_line = cursor[1]

  -- Only in diff buffers
  if buf ~= review.right_buf and buf ~= review.left_buf then
    return
  end

  -- Find current file
  if not review.current_file or not review.files[review.current_file] then
    return
  end
  local current_file = review.files[review.current_file]

  -- Find threads at cursor line for this file
  local threads = {}
  for _, comment in ipairs(review.existing_comments) do
    if comment.inline and comment.inline.path == current_file.path then
      local comment_line = comment.inline.to or comment.inline.from or 0
      if comment_line == cursor_line then
        table.insert(threads, comment)
      end
    end
  end

  if #threads == 0 then
    -- Hide thread panel if visible
    M.hide_thread_panel(review)
    return
  end

  -- Show threads in the opposite window
  local target_win
  if win == review.right_win then
    target_win = review.left_win
  else
    target_win = review.right_win
  end

  if not vim.api.nvim_win_is_valid(target_win) then
    return
  end

  -- Create a thread buffer
  local thread_buf = M.create_thread_buffer(threads, review)
  if not thread_buf then
    return
  end

  -- Store original buffer for restoration
  review._thread_panel = {
    win = target_win,
    original_buf = vim.api.nvim_win_get_buf(target_win),
    thread_buf = thread_buf,
  }

  -- Show in the target window
  vim.api.nvim_win_set_buf(target_win, thread_buf)

  -- Setup q keymap to dismiss
  vim.keymap.set("n", "q", function()
    M.hide_thread_panel(review)
  end, { buffer = thread_buf, silent = true, desc = "Close thread panel" })
end

--- Create a buffer with thread comments rendered.
--- @param threads table[] Array of comment objects
--- @param review table The review session
--- @return number|nil bufnr
function M.create_thread_buffer(threads, review)
  if #threads == 0 then
    return nil
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_option_value("filetype", constants.BUFFER_FILETYPE, { buf = bufnr })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = bufnr })
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_set_option_value("syntax", "markdown", { buf = bufnr })

  local line = 0

  -- Header
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
  writers.write_virtual_text(bufnr, constants.THREAD_HEADER_VT_NS, line, {
    { " Review Threads ", "BitbucketFilePanelTitle" },
  })
  line = line + 1

  -- Render each thread comment
  for _, comment in ipairs(threads) do
    local kind = comment.parent and "CommentReply" or "PullRequestReviewComment"
    local end_line, _ = writers.write_comment(bufnr, comment, kind, line)
    line = end_line

    -- Add diff snippet if available
    if comment.inline then
      vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
      local TCB = require("bitbucket.ui.text-chunk-builder")
      local snippet = TCB.new()
        :text("  ", nil)
        :text(comment.inline.path or "", "BitbucketFilePanelPath")
      if comment.inline.from then
        local from_line = tonumber(comment.inline.from) or comment.inline.from
        snippet:text(":" .. tostring(from_line), "BitbucketDetailsValue")
      end
      snippet:write(bufnr, constants.DIFFHUNK_VT_NS, line)
      line = line + 1
    end
  end

  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })

  return bufnr
end

--- Hide the thread panel and restore the original diff buffer.
function M.hide_thread_panel(review)
  if not review._thread_panel then
    return
  end

  local panel = review._thread_panel
  if vim.api.nvim_win_is_valid(panel.win) and vim.api.nvim_buf_is_valid(panel.original_buf) then
    vim.api.nvim_win_set_buf(panel.win, panel.original_buf)
  end

  if vim.api.nvim_buf_is_valid(panel.thread_buf) then
    vim.api.nvim_buf_delete(panel.thread_buf, { force = true })
  end

  review._thread_panel = nil
end

return M
