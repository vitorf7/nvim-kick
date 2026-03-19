-- Review system orchestration (octo.nvim parity)
-- Delegates layout, file panel, file entries, and thread panel to sub-modules.
local M = {}
local utils = require("bitbucket.utils")
local config = require("bitbucket.config")
local constants = require("bitbucket.constants")
local LayoutMod = require("bitbucket.reviews.layout")
local FilePanelMod = require("bitbucket.reviews.file-panel")
local FileEntryMod = require("bitbucket.reviews.file-entry")
local thread_panel = require("bitbucket.reviews.thread-panel")
local window = require("bitbucket.ui.window")

-- Active review sessions
M.active_reviews = {}
M.current_review = nil

-- ============================================================================
-- Start / Resume / Discard
-- ============================================================================

function M.start(opts, callback)
  opts = opts or {}
  callback = callback or function() end

  if not opts.id then
    callback(false, "PR ID is required")
    return
  end

  local workspace = opts.workspace
  local repo = opts.repo

  utils.info("Starting review for PR #" .. opts.id .. "...")

  local api = require("bitbucket.api")
  api.pullrequests.get({
    workspace = workspace,
    repo = repo,
    id = opts.id,
  }, function(success, pr, err)
    if not success then
      callback(false, "Failed to load PR: " .. (err or "unknown"))
      return
    end

    -- Create review session
    local review = {
      id = "review_" .. opts.id .. "_" .. os.time(),
      pr = pr,
      workspace = workspace,
      repo = repo,
      comments = {},
      files = {},
      file_entries = {},
      viewed_files = {},
      current_file = nil,
      layout = nil,
      existing_comments = {},
    }

    M.current_review = review
    M.active_reviews[review.id] = review

    -- Initialize layout using Layout module
    local layout = LayoutMod.new()
    layout:init_layout()
    review.tabnr = layout.tabnr
    review.file_panel_win = layout.file_panel_win
    review.file_panel_buf = layout.file_panel_buf
    review.left_win = layout.left_win
    review.left_buf = layout.left_buf
    review.right_win = layout.right_win
    review.right_buf = layout.right_buf
    review.layout_obj = layout

    -- Create FilePanel instance
    review.file_panel = FilePanelMod.new(layout.file_panel_buf, layout.file_panel_win, review)

    -- Load data and render
    M.load_review_data(review, function(success2, err2)
      if success2 then
        -- Setup keymaps
        M.setup_review_keymaps(review)
        M.setup_file_panel_keymaps(review)

        -- Setup CursorHold for thread auto-show
        if config.values.reviews and config.values.reviews.auto_show_threads then
          vim.api.nvim_create_autocmd("CursorHold", {
            buffer = review.right_buf,
            callback = function()
              thread_panel.show_review_threads(review)
            end,
          })
        end

        utils.info("Review session started. Use `<localleader>vs` to submit, `<C-c>` to close.")
        callback(true, nil)
      else
        M.close_review(review)
        callback(false, err2)
      end
    end)
  end)
end

function M.resume(callback)
  callback = callback or function() end
  if M.current_review then
    utils.info("Resuming review for PR #" .. M.current_review.pr.id)
    vim.api.nvim_set_current_tabpage(M.current_review.tabnr)
    callback(true, nil)
  else
    utils.warn("No pending review to resume")
    callback(false, "No pending review")
  end
end

function M.discard(callback)
  callback = callback or function() end
  local review = M.current_review
  if not review then
    callback(false, "No active review")
    return
  end
  M.close_review(review)
  M.current_review = nil
  utils.info("Review discarded")
  callback(true, nil)
end

-- ============================================================================
-- Data Loading
-- ============================================================================

function M.load_review_data(review, callback)
  local api = require("bitbucket.api")

  api.pullrequests.get_diff({
    workspace = review.workspace,
    repo = review.repo,
    id = review.pr.id,
  }, function(success, diff_data, err)
    if not success then
      callback(false, "Failed to load diff: " .. (err or "unknown"))
      return
    end

    review.files = M.parse_diff_files(diff_data)

    -- Create FileEntry objects
    review.file_entries = {}
    for _, file in ipairs(review.files) do
      table.insert(review.file_entries, FileEntryMod.new(file))
    end

    -- Load comments
    api.comments.list({
      workspace = review.workspace,
      repo = review.repo,
      id = review.pr.id,
    }, function(success2, comments_data, _)
      if success2 then
        review.existing_comments = comments_data.values or {}
      else
        review.existing_comments = {}
      end

      -- Render file panel
      review.file_panel:render()

      -- Show first file
      if #review.files > 0 then
        M.show_file(review, 1)
      end

      callback(true, nil)
    end)
  end)
end

function M.parse_diff_files(diff_data)
  local files = {}
  local diff_text = ""

  if type(diff_data) == "string" then
    diff_text = diff_data
  elseif type(diff_data) == "table" and diff_data.raw then
    diff_text = diff_data.raw
  end

  for line in diff_text:gmatch("[^\r\n]+") do
    if line:match("^diff %-%-git") then
      local old_file, new_file = line:match("a/(.-) b/(.+)$")
      if new_file then
        table.insert(files, {
          path = new_file,
          old_path = old_file,
          status = "modified",
          hunks = {},
          additions = 0,
          deletions = 0,
        })
      end
    elseif #files > 0 then
      local current_file = files[#files]
      if line:match("^new file mode") then
        current_file.status = "added"
      elseif line:match("^deleted file mode") then
        current_file.status = "removed"
      elseif line:match("^rename from") then
        current_file.status = "renamed"
      elseif line:match("^@@") then
        local old_start, old_count = line:match("@@ %%-(%d+),?(%d*)")
        local new_start, new_count = line:match("%+(%d+),?(%d*) @@")
        table.insert(current_file.hunks, {
          old_start = tonumber(old_start) or 0,
          old_count = tonumber(old_count) or 1,
          new_start = tonumber(new_start) or 0,
          new_count = tonumber(new_count) or 1,
          lines = {},
        })
      elseif #current_file.hunks > 0 then
        table.insert(current_file.hunks[#current_file.hunks].lines, line)
        if line:sub(1, 1) == "+" then
          current_file.additions = current_file.additions + 1
        elseif line:sub(1, 1) == "-" then
          current_file.deletions = current_file.deletions + 1
        end
      end
    end
  end

  return files
end

-- ============================================================================
-- File Navigation
-- ============================================================================

function M.show_file(review, file_index)
  if file_index < 1 or file_index > #review.files then
    return
  end

  review.current_file = file_index

  -- Load content via FileEntry
  local entry = review.file_entries[file_index]
  if entry then
    entry:load_buffers(review)
  end

  -- Re-render file panel to update highlighting
  review.file_panel:render()

  -- Render inline comments for this file
  M.render_file_comments(review, review.files[file_index])

  -- Focus configured side
  if review.layout_obj then
    review.layout_obj:set_current_file(review.files[file_index])
  end
end

function M.next_file(review)
  local next = (review.current_file or 0) + 1
  if next > #review.files then next = 1 end
  M.show_file(review, next)
end

function M.prev_file(review)
  local prev = (review.current_file or 2) - 1
  if prev < 1 then prev = #review.files end
  M.show_file(review, prev)
end

function M.toggle_viewed(review)
  if not review.current_file then return end
  local file = review.files[review.current_file]
  if review.viewed_files[file.path] then
    review.viewed_files[file.path] = nil
    utils.info("Marked as unviewed: " .. file.path)
  else
    review.viewed_files[file.path] = true
    utils.info("Marked as viewed: " .. file.path)
  end
  review.file_panel:render()
end

-- ============================================================================
-- File Comments
-- ============================================================================

function M.render_file_comments(review, file)
  vim.api.nvim_buf_clear_namespace(review.right_buf, constants.COMMENT_NS, 0, -1)

  for _, comment in ipairs(review.existing_comments or {}) do
    if comment.inline and comment.inline.path == file.path then
      local line = (comment.inline.to or comment.inline.from or 1) - 1
      require("bitbucket.ui.signs").place("thread", review.right_buf, line + 1)
      vim.api.nvim_buf_set_extmark(review.right_buf, constants.COMMENT_NS, line, 0, {
        virt_text = { { " " .. (comment.user and comment.user.display_name or "?") .. ": " .. (comment.content and comment.content.raw or ""):gsub("\n", " "):sub(1, 50), "BitbucketComment" } },
        virt_text_pos = "eol",
      })
    end
  end
end

-- ============================================================================
-- Review Comments
-- ============================================================================

function M.add_review_comment(review)
  local winnr = review.right_win
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  local line = cursor[1]

  if not review.current_file or not review.files[review.current_file] then
    utils.error("No file selected")
    return
  end

  local file = review.files[review.current_file]
  M.open_comment_editor(review, file, line)
end

function M.open_comment_editor(review, file, line)
  local float = window.create_centered_float({
    pct_width = 0.5,
    pct_height = 0.3,
    header = string.format(" Comment on %s:%d ", file.path, line),
  })

  vim.api.nvim_set_option_value("filetype", "markdown", { buf = float.bufnr })

  vim.api.nvim_buf_set_lines(float.bufnr, 0, -1, false, {
    "",
    " Enter your comment. Press <C-s> to submit, <C-c> to cancel.",
    "",
  })
  vim.api.nvim_win_set_cursor(float.winnr, { 4, 0 })

  local opts = { buffer = float.bufnr }

  vim.keymap.set("n", "<C-s>", function()
    local content_lines = vim.api.nvim_buf_get_lines(float.bufnr, 3, -1, false)
    local content = table.concat(content_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
    if content == "" then
      utils.warn("Cannot post empty comment")
      return
    end
    vim.api.nvim_win_close(float.winnr, true)

    table.insert(review.comments, {
      file_path = file.path,
      line = line,
      content = content,
    })

    vim.api.nvim_buf_set_extmark(review.right_buf, constants.COMMENT_NS, line - 1, 0, {
      sign_text = "▎",
      sign_hl_group = "BitbucketReviewComment",
      virt_text = { { " [Pending comment]", "BitbucketReviewComment" } },
      virt_text_pos = "eol",
    })

    utils.info("Comment added to review (not yet submitted). " .. #review.comments .. " pending comment(s)")
  end, opts)

  vim.keymap.set("n", "<C-c>", function()
    vim.api.nvim_win_close(float.winnr, true)
  end, opts)

  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(float.winnr, true)
  end, opts)
end

-- ============================================================================
-- Submit
-- ============================================================================

function M.submit(callback)
  callback = callback or function() end
  local review = M.current_review
  if not review then
    callback(false, "No active review")
    return
  end

  if #review.comments == 0 then
    M.submit_review_state(review, callback)
    return
  end

  local api = require("bitbucket.api")
  local submitted = 0
  local failed = 0

  for _, comment in ipairs(review.comments) do
    api.comments.create({
      workspace = review.workspace,
      repo = review.repo,
      id = review.pr.id,
      content = comment.content,
      inline = {
        path = comment.file_path,
        line_from = comment.line,
        line_to = comment.line,
      },
    }, function(success, _, err)
      if success then
        submitted = submitted + 1
      else
        failed = failed + 1
        utils.error("Failed to submit comment: " .. (err or "unknown"))
      end
      if submitted + failed == #review.comments then
        if failed == 0 then
          M.submit_review_state(review, callback)
        else
          callback(false, string.format("Failed to submit %d comment(s)", failed))
        end
      end
    end)
  end
end

function M.submit_review_state(review, callback)
  -- Use centered float for review submission (octo-style)
  local choices = { "Comment", "Approve", "Request Changes" }

  vim.ui.select(choices, {
    prompt = "Submit review as:",
  }, function(choice)
    if not choice then
      callback(false, "Cancelled")
      return
    end

    local api = require("bitbucket.api")

    if choice == "Approve" then
      api.pullrequests.approve({
        workspace = review.workspace,
        repo = review.repo,
        id = review.pr.id,
      }, function(success, _, err)
        if success then
          utils.info("Review approved!")
          M.close_review(review)
          callback(true, nil)
        else
          callback(false, "Failed to approve: " .. (err or "unknown"))
        end
      end)
    elseif choice == "Request Changes" then
      api.pullrequests.request_changes({
        workspace = review.workspace,
        repo = review.repo,
        id = review.pr.id,
      }, function(success, _, err)
        if success then
          utils.info("Changes requested!")
        else
          utils.warn("Request changes API call failed, comments were posted.")
        end
        M.close_review(review)
        callback(true, nil)
      end)
    else
      utils.info("Review commented!")
      M.close_review(review)
      callback(true, nil)
    end
  end)
end

-- ============================================================================
-- Keymaps
-- ============================================================================

function M.setup_review_keymaps(review)
  local function map(mode, lhs, rhs, opts)
    opts = vim.tbl_extend("force", { buffer = review.right_buf, silent = true }, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
  end

  local mappings = config.values.mappings.review_diff

  map({ "n", "x" }, mappings.add_review_comment.lhs, function()
    M.add_review_comment(review)
  end, { desc = mappings.add_review_comment.desc })

  map("n", mappings.submit_review.lhs, function()
    M.submit(function() end)
  end, { desc = mappings.submit_review.desc })

  map("n", mappings.discard_review.lhs, function()
    M.discard(function() end)
  end, { desc = mappings.discard_review.desc })

  map("n", mappings.select_next_entry.lhs, function()
    M.next_file(review)
  end, { desc = mappings.select_next_entry.desc })

  map("n", mappings.select_prev_entry.lhs, function()
    M.prev_file(review)
  end, { desc = mappings.select_prev_entry.desc })

  map("n", mappings.toggle_viewed.lhs, function()
    M.toggle_viewed(review)
  end, { desc = mappings.toggle_viewed.desc })

  map("n", mappings.next_thread.lhs, function()
    thread_panel.show_review_threads(review, true)
  end, { desc = mappings.next_thread.desc })

  map("n", mappings.prev_thread.lhs, function()
    thread_panel.show_review_threads(review, true)
  end, { desc = mappings.prev_thread.desc })

  map("n", mappings.focus_files.lhs, function()
    vim.api.nvim_set_current_win(review.file_panel_win)
  end, { desc = mappings.focus_files.desc })

  map("n", mappings.close_review_tab.lhs, function()
    M.close_review(review)
  end, { desc = mappings.close_review_tab.desc })
end

function M.setup_file_panel_keymaps(review)
  local function map(mode, lhs, rhs, opts)
    opts = vim.tbl_extend("force", { buffer = review.file_panel_buf, silent = true }, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
  end

  local mappings = config.values.mappings.file_panel

  map("n", mappings.next_entry.lhs, function()
    local current = review.current_file or 0
    if current < #review.files then
      M.show_file(review, current + 1)
    end
  end, { desc = mappings.next_entry.desc })

  map("n", mappings.prev_entry.lhs, function()
    local current = review.current_file or 0
    if current > 1 then
      M.show_file(review, current - 1)
    end
  end, { desc = mappings.prev_entry.desc })

  map("n", mappings.select_entry.lhs, function()
    local line = vim.api.nvim_win_get_cursor(review.file_panel_win)[1]
    local file_index = line - 3
    if file_index >= 1 and file_index <= #review.files then
      M.show_file(review, file_index)
      vim.api.nvim_set_current_win(review.right_win)
    end
  end, { desc = mappings.select_entry.desc })

  map("n", mappings.toggle_viewed.lhs, function()
    M.toggle_viewed(review)
  end, { desc = mappings.toggle_viewed.desc })

  map("n", mappings.refresh_files.lhs, function()
    review.file_panel:render()
  end, { desc = mappings.refresh_files.desc })

  map("n", mappings.focus_files.lhs, function()
    vim.api.nvim_set_current_win(review.file_panel_win)
  end, { desc = mappings.focus_files.desc })

  map("n", mappings.toggle_files.lhs, function()
    if vim.api.nvim_win_is_valid(review.file_panel_win) then
      local width = vim.api.nvim_win_get_width(review.file_panel_win)
      if width > 1 then
        vim.api.nvim_win_set_width(review.file_panel_win, 1)
      else
        vim.api.nvim_win_set_width(review.file_panel_win, 40)
      end
    end
  end, { desc = mappings.toggle_files.desc })

  map("n", mappings.submit_review.lhs, function()
    M.submit(function() end)
  end, { desc = mappings.submit_review.desc })

  map("n", mappings.discard_review.lhs, function()
    M.discard(function() end)
  end, { desc = mappings.discard_review.desc })

  map("n", mappings.close_review_tab.lhs, function()
    M.close_review(review)
  end, { desc = mappings.close_review_tab.desc })
end

-- ============================================================================
-- Close
-- ============================================================================

function M.close_review(review)
  -- Hide thread panel if visible
  thread_panel.hide_thread_panel(review)

  -- Close layout
  if review.layout_obj then
    review.layout_obj:close()
  elseif review.tabnr and vim.api.nvim_tabpage_is_valid(review.tabnr) then
    pcall(vim.cmd, "tabclose " .. vim.api.nvim_tabpage_get_number(review.tabnr))
  end

  M.active_reviews[review.id] = nil
  if M.current_review == review then
    M.current_review = nil
  end
end

return M
