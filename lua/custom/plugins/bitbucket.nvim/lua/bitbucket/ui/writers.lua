-- UI Writers module (octo.nvim parity)
-- The heart of bitbucket.nvim's UI. Handles writing all content to buffers
-- using virtual text overlays, extmark-tracked editable regions, and rich formatting.
local M = {}

local constants = require("bitbucket.constants")
local config = require("bitbucket.config")
local bubbles = require("bitbucket.ui.bubbles")
local TextChunkBuilder = require("bitbucket.ui.text-chunk-builder")
local TitleMetadata = require("bitbucket.model.title-metadata")
local BodyMetadata = require("bitbucket.model.body-metadata")
local CommentMetadata = require("bitbucket.model.comment-metadata")

-- ============================================================================
-- Core Writing Primitives
-- ============================================================================

--- Insert lines into a buffer at a specific position.
--- Optionally creates an extmark spanning the block for tracking editable regions.
--- @param bufnr number
--- @param lines string[] Lines to insert
--- @param line number 0-indexed insertion line
--- @param mark boolean|nil Whether to create a tracking extmark
--- @return number|nil extmark_id The extmark ID if mark=true
--- @return number end_line The line after the inserted block
function M.write_block(bufnr, lines, line, mark)
  if not lines or #lines == 0 then
    lines = { "" }
  end

  -- Insert an empty line before, the content, and two empty lines after
  local block = { "" }
  vim.list_extend(block, lines)
  table.insert(block, "")
  table.insert(block, "")

  vim.api.nvim_buf_set_lines(bufnr, line, line, false, block)

  local extmark_id = nil
  if mark then
    extmark_id = vim.api.nvim_buf_set_extmark(bufnr, constants.COMMENT_NS, line, 0, {
      end_line = line + #block - 1,
      end_col = 0,
      right_gravity = false,
      end_right_gravity = true,
    })
  end

  return extmark_id, line + #block
end

--- Write virtual text (overlay mode) at a specific line.
--- @param bufnr number
--- @param ns number Namespace ID
--- @param line number 0-indexed line number
--- @param chunks table[] Virtual text chunks
function M.write_virtual_text(bufnr, ns, line, chunks)
  if not chunks or #chunks == 0 then
    return
  end
  vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
    virt_text = chunks,
    virt_text_pos = "overlay",
    hl_mode = "combine",
  })
end

--- Write a detail table: insert empty lines then overlay virtual text on each.
--- @param opts table { bufnr, ns, start_line, details = { lines = {"",...}, vt = {{chunks},...} } }
--- @return number The line after the detail table
function M.write_detail_table(opts)
  local bufnr = opts.bufnr
  local ns = opts.ns or constants.DETAILS_NS
  local start_line = opts.start_line
  local details = opts.details

  -- Insert all empty lines at once
  vim.api.nvim_buf_set_lines(bufnr, start_line, start_line, false, details.lines)

  -- Overlay virtual text on each
  for i, vt in ipairs(details.vt) do
    if vt and #vt > 0 then
      M.write_virtual_text(bufnr, ns, start_line + i - 1, vt)
    end
  end

  return start_line + #details.lines
end

-- ============================================================================
-- Title Rendering
-- ============================================================================

--- Write the PR/issue title as an extmark-tracked editable region.
--- @param bufnr number
--- @param title string The title text
--- @param line number 0-indexed line to start writing
--- @return number next_line The line after the title
--- @return TitleMetadata metadata The title metadata for dirty tracking
function M.write_title(bufnr, title, line)
  title = title or ""

  -- Write the title text
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { title })

  -- Apply title highlight extmark
  vim.api.nvim_buf_set_extmark(bufnr, constants.HIGHLIGHT_NS, line, 0, {
    end_line = line,
    end_col = #title,
    hl_group = "BitbucketIssueTitle",
  })

  -- Add empty line after title
  vim.api.nvim_buf_set_lines(bufnr, line + 1, line + 1, false, { "" })

  -- Create tracking extmark for editing
  local extmark = vim.api.nvim_buf_set_extmark(bufnr, constants.COMMENT_NS, line, 0, {
    end_line = line,
    end_col = #title,
    right_gravity = false,
    end_right_gravity = true,
  })

  local metadata = TitleMetadata.new({
    savedBody = title,
    body = title,
    extmark = extmark,
    startLine = line,
    endLine = line,
  })

  return line + 2, metadata
end

-- ============================================================================
-- State Rendering
-- ============================================================================

--- Write the PR state as a bubble on line 0 using virtual text.
--- @param bufnr number
--- @param state string PR state (OPEN, MERGED, DECLINED, etc.)
--- @param number number PR number
--- @param is_draft boolean|nil
function M.write_state(bufnr, state, number, is_draft)
  -- Clear existing state virtual text
  vim.api.nvim_buf_clear_namespace(bufnr, constants.TITLE_VT_NS, 0, 1)

  local builder = TextChunkBuilder.new()
    :state_with_icon(state, is_draft)
    :text("  #" .. (number or ""), "BitbucketIssueId")

  builder:write(bufnr, constants.TITLE_VT_NS, 0)
end

-- ============================================================================
-- Details Panel
-- ============================================================================

--- Write the full PR metadata details panel as virtual text overlays.
--- @param bufnr number
--- @param pr table The PR data object from the API
--- @param start_line number 0-indexed start line
--- @param update boolean|nil Whether this is an update (clears existing)
--- @return number next_line The line after the details
function M.write_details(bufnr, pr, start_line, update)
  if update then
    vim.api.nvim_buf_clear_namespace(bufnr, constants.DETAILS_NS, 0, -1)
  end

  local details = { lines = {}, vt = {} }

  -- Helper to add a detail row
  local function add_detail(label, value_chunks)
    local builder = TextChunkBuilder.new():detail_label(label)
    -- Append value chunks
    local chunks = builder:build()
    for _, chunk in ipairs(value_chunks) do
      table.insert(chunks, chunk)
    end
    table.insert(details.lines, "")
    table.insert(details.vt, chunks)
  end

  -- Repo
  local repo_slug = ""
  if pr.destination and pr.destination.repository then
    repo_slug = pr.destination.repository.full_name or ""
  end
  if repo_slug == "" then
    repo_slug = string.format("%s/%s", pr.workspace or "", pr.repo or "")
  end
  add_detail("Repo: ", { { repo_slug, "BitbucketDetailsValue" } })

  -- Author
  if pr.author then
    local author_name = pr.author.display_name or pr.author.nickname or "Unknown"
    local author_chunks = bubbles.make_user_bubble(author_name, false, { margin_width = 0 })
    add_detail("Author: ", author_chunks)
  end

  -- Created date
  if pr.created_on then
    add_detail("Created: ", { { M.format_relative_time(pr.created_on), "BitbucketDate" } })
  end

  -- Updated date
  if pr.updated_on then
    add_detail("Updated: ", { { M.format_relative_time(pr.updated_on), "BitbucketDate" } })
  end

  -- Reviewers with review state
  if pr.reviewers and #pr.reviewers > 0 then
    local reviewer_chunks = {}
    for i, reviewer in ipairs(pr.reviewers) do
      if i > 1 then
        table.insert(reviewer_chunks, { ", " })
      end
      local name = reviewer.display_name or reviewer.nickname or "Unknown"

      -- Find review state from participants
      local state_icon = ""
      if pr.participants then
        for _, p in ipairs(pr.participants) do
          if p.user and p.user.uuid == reviewer.uuid then
            if p.approved then
              state_icon = " "
            elseif p.state == "changes_requested" then
              state_icon = " "
            elseif p.role == "REVIEWER" then
              state_icon = " "
            end
            break
          end
        end
      end

      local user_chunks = bubbles.make_user_bubble(name, false, { margin_width = 0 })
      vim.list_extend(reviewer_chunks, user_chunks)
      if state_icon ~= "" then
        local state_hl = state_icon == " " and "BitbucketStateApproved"
          or state_icon == " " and "BitbucketStateChangesRequested"
          or "BitbucketStateCommented"
        table.insert(reviewer_chunks, { state_icon, state_hl })
      end
    end
    add_detail("Reviewers: ", reviewer_chunks)
  else
    add_detail("Reviewers: ", { { "No one assigned", "BitbucketMissingDetails" } })
  end

  -- Branch info
  if pr.source and pr.destination then
    local src_branch = pr.source.branch and pr.source.branch.name or "?"
    local dst_branch = pr.destination.branch and pr.destination.branch.name or "?"
    add_detail("From: ", {
      { src_branch, "BitbucketDetailsValue" },
      { "  Into: ", "BitbucketDetailsLabel" },
      { dst_branch, "BitbucketDetailsValue" },
    })
  end

  -- Merge state
  if pr.state == "MERGED" and pr.closed_by then
    local merged_by = pr.closed_by.display_name or "Unknown"
    local merge_chunks = bubbles.make_user_bubble(merged_by, false, { margin_width = 0 })
    add_detail("Merged by: ", merge_chunks)
  end

  -- Tasks
  if pr.task_count and pr.task_count > 0 then
    add_detail("Tasks: ", { { tostring(pr.task_count), "BitbucketDetailsValue" } })
  end

  -- Changes diffstat histogram
  local comment_count = pr.comment_count or 0
  local stats_chunks = {
    { tostring(comment_count), "BitbucketDetailsValue" },
  }

  -- If we have diffstat data, add histogram
  if pr.diffstat then
    local additions = 0
    local deletions = 0
    for _, file_stat in ipairs(pr.diffstat) do
      additions = additions + (file_stat.lines_added or 0)
      deletions = deletions + (file_stat.lines_removed or 0)
    end
    table.insert(stats_chunks, { "  ", nil })
    table.insert(stats_chunks, { "+" .. additions, "BitbucketDiffstatAdditions" })
    table.insert(stats_chunks, { " ", nil })
    table.insert(stats_chunks, { "-" .. deletions, "BitbucketDiffstatDeletions" })

    -- Histogram blocks
    local total = additions + deletions
    if total > 0 then
      local width = 5
      local add_blocks = math.floor(additions / total * width + 0.5)
      local del_blocks = width - add_blocks
      table.insert(stats_chunks, { "  ", nil })
      if add_blocks > 0 then
        table.insert(stats_chunks, { string.rep("■", add_blocks), "BitbucketDiffstatAdditions" })
      end
      if del_blocks > 0 then
        table.insert(stats_chunks, { string.rep("■", del_blocks), "BitbucketDiffstatDeletions" })
      end
    end
  end

  add_detail("Comments: ", stats_chunks)

  -- Empty line after details
  table.insert(details.lines, "")
  table.insert(details.vt, {})

  return M.write_detail_table({
    bufnr = bufnr,
    ns = constants.DETAILS_NS,
    start_line = start_line,
    details = details,
  })
end

-- ============================================================================
-- Body Rendering
-- ============================================================================

--- Write the PR/issue body as an extmark-tracked editable block.
--- @param bufnr number
--- @param body string|nil The body/description text
--- @param line number 0-indexed start line
--- @param viewer_can_update boolean|nil
--- @return number next_line
--- @return BodyMetadata|nil metadata
function M.write_body(bufnr, body, line, viewer_can_update)
  body = body or ""

  -- Normalize body text
  body = vim.trim(body)
  body = body:gsub("\r\n", "\n")

  if body == "" then
    -- Empty body placeholder
    vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "", "" })
    M.write_virtual_text(bufnr, constants.EMPTY_MSG_VT_NS, line, {
      { "No description provided.", "BitbucketMissingDetails" },
    })

    local extmark = vim.api.nvim_buf_set_extmark(bufnr, constants.COMMENT_NS, line, 0, {
      end_line = line + 1,
      end_col = 0,
      right_gravity = false,
      end_right_gravity = true,
    })

    local metadata = BodyMetadata.new({
      savedBody = "",
      extmark = extmark,
      startLine = line,
      endLine = line + 1,
      viewerCanUpdate = viewer_can_update,
    })

    return line + 2, metadata
  end

  -- Split body into lines
  local body_lines = {}
  for text_line in body:gmatch("[^\n]*") do
    table.insert(body_lines, text_line)
  end

  -- Write block with extmark tracking
  local extmark_id, next_line = M.write_block(bufnr, body_lines, line, true)

  local metadata = BodyMetadata.new({
    savedBody = body,
    extmark = extmark_id,
    startLine = line,
    endLine = next_line - 1,
    viewerCanUpdate = viewer_can_update,
  })

  return next_line, metadata
end

-- ============================================================================
-- Comment Rendering
-- ============================================================================

--- Write a single comment with octo-style formatting.
--- Supports multiple comment kinds with different header formats.
--- @param bufnr number
--- @param comment table The comment data from API
--- @param kind string Comment kind: "PullRequestComment"|"PullRequestReviewComment"|"CommentReply"
--- @param line number 0-indexed start line
--- @return number end_line
--- @return CommentMetadata metadata
function M.write_comment(bufnr, comment, kind, line)
  kind = kind or "PullRequestComment"
  local start_line = line
  local ns = vim.api.nvim_create_namespace("bitbucket_comment_header_" .. (comment.id or os.time()))

  -- Empty line before comment
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
  line = line + 1

  -- Build header using TextChunkBuilder
  local author_name = "Unknown"
  if comment.user then
    author_name = comment.user.display_name or comment.user.nickname or "Unknown"
  end

  local builder = TextChunkBuilder.new()

  if kind == "PullRequestReviewComment" then
    builder:indented_marker(1)
      :heading("THREAD COMMENT: ")
      :user_plain(author_name, false)
  elseif kind == "CommentReply" then
    builder:indented_marker(1)
      :heading("REPLY: ")
      :user_plain(author_name, false)
  else
    builder:timeline_marker("commit")
      :heading("COMMENT: ")
      :user_plain(author_name, false)
  end

  -- Add date
  if comment.created_on then
    builder:text(" ", nil):date(comment.created_on)
  end

  -- Write header as virtual text
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
  builder:write(bufnr, ns, line)
  line = line + 1

  -- Comment body (actual buffer lines, editable)
  local content = comment.content
  if type(content) == "table" and content.raw then
    content = content.raw
  end
  content = content or ""
  content = vim.trim(content)

  local content_lines = {}
  if content ~= "" then
    for text_line in content:gmatch("[^\r\n]*") do
      table.insert(content_lines, text_line)
    end
  end
  if #content_lines == 0 then
    content_lines = { "" }
  end

  -- Write content as tracked block
  local extmark_id = vim.api.nvim_buf_set_extmark(bufnr, constants.COMMENT_NS, line, 0, {
    end_line = line,
    end_col = 0,
    right_gravity = false,
    end_right_gravity = true,
  })

  vim.api.nvim_buf_set_lines(bufnr, line, line, false, content_lines)
  line = line + #content_lines

  -- Update extmark to span the content
  vim.api.nvim_buf_set_extmark(bufnr, constants.COMMENT_NS, extmark_id, 0, {
    id = extmark_id,
    end_line = line - 1,
    end_col = #(content_lines[#content_lines] or ""),
  })

  -- Diff snippet for inline comments
  if comment.inline and comment.inline.path then
    vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
    local snippet_builder = TextChunkBuilder.new()
      :text("  ", nil)
      :text(comment.inline.path, "BitbucketFilePanelPath")
    if comment.inline.from then
      local from_line = tonumber(comment.inline.from) or comment.inline.from
      snippet_builder:text(":" .. tostring(from_line), "BitbucketDetailsValue")
    end
    if comment.inline.to then
      local to_line = tonumber(comment.inline.to) or comment.inline.to
      snippet_builder:text("-" .. tostring(to_line), "BitbucketDetailsValue")
    end
    snippet_builder:write(bufnr, constants.DIFFHUNK_VT_NS, line)
    line = line + 1
  end

  local end_line = line

  local metadata = CommentMetadata.new({
    id = comment.id,
    author = comment.user,
    savedBody = content,
    body = content,
    extmark = extmark_id,
    namespace = ns,
    viewerCanUpdate = comment.viewerCanUpdate or false,
    viewerCanDelete = comment.viewerCanDelete or false,
    viewerDidAuthor = comment.viewerDidAuthor or false,
    kind = kind,
    replyTo = comment.parent and comment.parent.id,
    path = comment.inline and comment.inline.path,
    startLine = start_line,
    endLine = end_line,
  })

  return end_line, metadata
end

-- ============================================================================
-- Diff Snippet Rendering
-- ============================================================================

--- Write a diff hunk snippet with box-drawing border and syntax highlighting.
--- @param bufnr number
--- @param diffhunk string The diff hunk text
--- @param line number 0-indexed start line
--- @param filepath string|nil The file path for treesitter lang detection
--- @return number next_line
function M.write_thread_snippet(bufnr, diffhunk, line, filepath)
  if not diffhunk or diffhunk == "" then
    return line
  end

  local hunk_lines = {}
  for hunk_line in diffhunk:gmatch("[^\r\n]+") do
    table.insert(hunk_lines, hunk_line)
  end

  if #hunk_lines == 0 then
    return line
  end

  -- Calculate max width for the box
  local max_width = 0
  for _, hl in ipairs(hunk_lines) do
    max_width = math.max(max_width, #hl)
  end
  max_width = math.min(max_width + 8, 80)

  local ns = constants.DIFFHUNK_VT_NS

  -- Top border
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
  local top_border = "┌" .. string.rep("─", max_width) .. "┐"
  M.write_virtual_text(bufnr, ns, line, { { top_border, "BitbucketThread" } })
  line = line + 1

  -- Content lines with side borders
  for _, hunk_line in ipairs(hunk_lines) do
    vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })

    local hl = "Normal"
    local prefix = hunk_line:sub(1, 1)
    if prefix == "+" then
      hl = "DiffAdd"
    elseif prefix == "-" then
      hl = "DiffDelete"
    elseif prefix == "@" then
      hl = "BitbucketCommentHeader"
    end

    local padded = hunk_line .. string.rep(" ", max_width - #hunk_line)
    M.write_virtual_text(bufnr, ns, line, {
      { "│", "BitbucketThread" },
      { padded, hl },
      { "│", "BitbucketThread" },
    })
    line = line + 1
  end

  -- Bottom border
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
  local bottom_border = "└" .. string.rep("─", max_width) .. "┘"
  M.write_virtual_text(bufnr, ns, line, { { bottom_border, "BitbucketThread" } })
  line = line + 1

  return line
end

-- ============================================================================
-- Timeline Event Rendering
-- ============================================================================

--- Write all timeline items from the PR activity log.
--- @param bufnr number
--- @param activity_list table[] Array of activity objects from the API
--- @param line number 0-indexed start line
--- @return number next_line
function M.write_timeline_items(bufnr, activity_list, line)
  if not activity_list or #activity_list == 0 then
    return line
  end

  -- Section header
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
  line = line + 1

  -- Process each activity
  local i = 1
  while i <= #activity_list do
    local activity = activity_list[i]

    if activity.comment then
      line = M._write_comment_event(bufnr, activity.comment, line)
    elseif activity.update then
      line = M._write_update_event(bufnr, activity.update, line)
    elseif activity.approval then
      line = M._write_approval_event(bufnr, activity.approval, line)
    elseif activity.changes_requested then
      line = M._write_changes_requested_event(bufnr, activity.changes_requested, line)
    end

    i = i + 1
  end

  return line
end

--- Write a comment activity event
function M._write_comment_event(bufnr, comment, line)
  local author = comment.user and (comment.user.display_name or comment.user.nickname) or "Unknown"
  local preview = ""
  if comment.content and comment.content.raw then
    preview = comment.content.raw:gsub("\n", " "):sub(1, 60)
    if #comment.content.raw > 60 then
      preview = preview .. "..."
    end
  end

  local builder = TextChunkBuilder.new()
    :timeline_marker("commit")
    :user_plain(author, false)
    :heading(" commented")

  if comment.created_on then
    builder:text(" ", nil):date(comment.created_on)
  end

  if preview ~= "" then
    builder:text(" - ", "BitbucketTimelineItemHeading")
      :text(preview, "BitbucketCommentHeader")
  end

  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
  builder:write(bufnr, constants.EVENT_VT_NS, line)
  return line + 1
end

--- Write an update activity event
function M._write_update_event(bufnr, update, line)
  local author = update.author and (update.author.display_name or update.author.nickname) or "Unknown"
  local state = update.state

  local builder = TextChunkBuilder.new()

  if state == "MERGED" then
    builder:timeline_marker("merged")
      :user_plain(author, false)
      :heading(" merged this pull request")
  elseif state == "DECLINED" then
    builder:timeline_marker("closed")
      :user_plain(author, false)
      :heading(" declined this pull request")
  elseif state == "OPEN" then
    builder:timeline_marker("reopened")
      :user_plain(author, false)
      :heading(" updated this pull request")
  else
    builder:timeline_marker("updated")
      :user_plain(author, false)
      :heading(" updated this pull request")
  end

  if update.date then
    builder:text(" ", nil):date(update.date)
  end

  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
  builder:write(bufnr, constants.EVENT_VT_NS, line)
  return line + 1
end

--- Write an approval activity event
function M._write_approval_event(bufnr, approval, line)
  local author = approval.user and (approval.user.display_name or approval.user.nickname) or "Unknown"

  local builder = TextChunkBuilder.new()
    :timeline_marker("approved")
    :user_plain(author, false)
    :heading(" approved this pull request")

  if approval.date then
    builder:text(" ", nil):date(approval.date)
  end

  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
  builder:write(bufnr, constants.EVENT_VT_NS, line)
  return line + 1
end

--- Write a changes_requested activity event
function M._write_changes_requested_event(bufnr, activity, line)
  local author = activity.user and (activity.user.display_name or activity.user.nickname) or "Unknown"

  local builder = TextChunkBuilder.new()
    :timeline_marker("changes_requested")
    :user_plain(author, false)
    :heading(" requested changes")

  if activity.date then
    builder:text(" ", nil):date(activity.date)
  end

  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })
  builder:write(bufnr, constants.EVENT_VT_NS, line)
  return line + 1
end

-- ============================================================================
-- Preview Rendering (for Telescope)
-- ============================================================================

--- Render a compact PR preview for Telescope.
--- @param pr table The PR data object
--- @param bufnr number The preview buffer
function M.pr_preview(pr, bufnr)
  local lines = {}
  local highlights = {}

  local state = pr.state or "OPEN"
  local state_icon = state == "MERGED" and "◌" or state == "DECLINED" and "○" or "●"
  local title_line = string.format("%s #%d %s", state_icon, pr.id or 0, pr.title or "")
  table.insert(lines, title_line)
  table.insert(highlights, {
    group = state == "MERGED" and "BitbucketStateMerged"
      or state == "DECLINED" and "BitbucketStateClosed"
      or "BitbucketStateOpen",
    line = 0,
    col_start = 0,
    col_end = #state_icon,
  })

  table.insert(lines, "")

  if pr.author then
    table.insert(lines, "Author: " .. (pr.author.display_name or "Unknown"))
  end

  if pr.source and pr.destination then
    local src = pr.source.branch and pr.source.branch.name or "?"
    local dst = pr.destination.branch and pr.destination.branch.name or "?"
    table.insert(lines, "Branch: " .. src .. " -> " .. dst)
  end

  if pr.created_on then
    table.insert(lines, "Created: " .. M.format_relative_time(pr.created_on))
  end

  table.insert(lines, "")

  local desc = pr.description or ""
  if desc ~= "" then
    table.insert(lines, "---")
    for desc_line in desc:gmatch("[^\r\n]+") do
      table.insert(lines, desc_line)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

  for _, hl in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(bufnr, -1, hl.group, hl.line, hl.col_start, hl.col_end)
  end
end

--- Render a compact issue preview for Telescope.
--- @param issue table The issue data object
--- @param bufnr number The preview buffer
function M.issue_preview(issue, bufnr)
  local lines = {}

  local state = issue.state or "open"
  local state_icon = (state == "open" or state == "new") and "●" or "○"
  table.insert(lines, string.format("%s #%d %s", state_icon, issue.id or 0, issue.title or ""))
  table.insert(lines, "")

  if issue.reporter then
    table.insert(lines, "Reporter: " .. (issue.reporter.display_name or "Unknown"))
  end

  if issue.assignee then
    table.insert(lines, "Assignee: " .. (issue.assignee.display_name or "Unassigned"))
  end

  table.insert(lines, "State: " .. state)

  if issue.created_on then
    table.insert(lines, "Created: " .. M.format_relative_time(issue.created_on))
  end

  table.insert(lines, "")

  if issue.content and issue.content.raw and issue.content.raw ~= "" then
    table.insert(lines, "---")
    for desc_line in issue.content.raw:gmatch("[^\r\n]+") do
      table.insert(lines, desc_line)
    end
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
end

-- ============================================================================
-- Progress Bar
-- ============================================================================

--- Create virtual text chunks for a progress bar.
--- @param percentage number 0-100
--- @param width number Number of characters
--- @return table[] Virtual text chunks
function M.make_progress_bar(percentage, width)
  width = width or 10
  percentage = math.max(0, math.min(100, percentage or 0))

  local filled = math.floor(percentage / 100 * width + 0.5)
  local empty = width - filled

  local chunks = {}
  if filled > 0 then
    table.insert(chunks, { string.rep("━", filled), "DiagnosticOk" })
  end
  if empty > 0 then
    table.insert(chunks, { string.rep("━", empty), "NonText" })
  end
  return chunks
end

-- ============================================================================
-- Section Headers and Rules (backward compat)
-- ============================================================================

--- Write a section header
function M.write_section_header(bufnr, header, line)
  local lines = { "", "---", "", "## " .. header, "" }
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, lines)
  vim.api.nvim_buf_add_highlight(bufnr, constants.HIGHLIGHT_NS, "BitbucketSectionHeader", line + 3, 0, -1)
  return line + 5
end

--- Write a horizontal rule
function M.write_horizontal_rule(bufnr, line)
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "", "---", "" })
  return line + 3
end

-- ============================================================================
-- Utility
-- ============================================================================

--- Format an ISO 8601 timestamp to relative time.
--- @param timestamp string
--- @return string
function M.format_relative_time(timestamp)
  if not timestamp then
    return ""
  end

  local year, month, day, hour, min, sec = timestamp:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  if not year then
    return timestamp
  end

  local time_sec = os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec),
  })

  local now = os.time()
  local diff = now - time_sec

  if diff < 60 then
    return "just now"
  elseif diff < 3600 then
    local mins = math.floor(diff / 60)
    return mins .. " minute" .. (mins == 1 and "" or "s") .. " ago"
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours .. " hour" .. (hours == 1 and "" or "s") .. " ago"
  elseif diff < 604800 then
    local days = math.floor(diff / 86400)
    return days .. " day" .. (days == 1 and "" or "s") .. " ago"
  else
    return os.date("%b %d, %Y", time_sec)
  end
end

return M
