-- BitbucketBuffer: Central buffer abstraction (octo.nvim parity)
-- Manages lifecycle, rendering, metadata tracking, dirty detection, and save.
local constants = require("bitbucket.constants")
local utils = require("bitbucket.utils")
local writers = require("bitbucket.ui.writers")
local config = require("bitbucket.config")
local signs_mod = require("bitbucket.ui.signs")

---@class BitbucketBuffer
---@field bufnr number
---@field kind "pull_request"|"issue"|"repo"
---@field number number
---@field workspace string
---@field repo string
---@field node table The raw data from API
---@field comments table List of comments
---@field activity table|nil Activity/timeline data
---@field titleMetadata TitleMetadata|nil
---@field bodyMetadata BodyMetadata|nil
---@field commentMetadata CommentMetadata[]
---@field threadMetadata ThreadMetadata[]
local BitbucketBuffer = {}
BitbucketBuffer.__index = BitbucketBuffer

-- ============================================================================
-- Construction
-- ============================================================================

function BitbucketBuffer:new(opts)
  opts = opts or {}

  local bufnr = vim.api.nvim_create_buf(false, true)

  local this = {
    bufnr = bufnr,
    kind = opts.kind,
    number = opts.number,
    workspace = opts.workspace,
    repo = opts.repo,
    node = opts.node,
    comments = {},
    activity = nil,
    -- Metadata for editable regions (octo-style)
    titleMetadata = nil,
    bodyMetadata = nil,
    commentMetadata = {},
    threadMetadata = {},
    -- Legacy compat
    metadata = {
      title = nil,
      body = nil,
      comment_regions = {},
    },
  }

  setmetatable(this, self)

  -- Register in global buffer table
  _G.bitbucket_buffers[bufnr] = this

  -- Setup buffer
  this:configure()

  return this
end

-- ============================================================================
-- Buffer Configuration (octo-style)
-- ============================================================================

function BitbucketBuffer:configure()
  local bufnr = self.bufnr

  -- Core buffer options
  vim.api.nvim_set_option_value("filetype", constants.BUFFER_FILETYPE, { buf = bufnr })
  vim.api.nvim_set_option_value("buftype", "acwrite", { buf = bufnr })
  vim.api.nvim_set_option_value("bufhidden", "hide", { buf = bufnr })
  vim.api.nvim_set_option_value("swapfile", false, { buf = bufnr })
  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })

  -- Buffer name using URI scheme
  local bufname = string.format(
    "bitbucket://%s/%s/%s/%d",
    self.workspace or "",
    self.repo or "",
    self.kind or "",
    self.number or 0
  )
  pcall(vim.api.nvim_buf_set_name, bufnr, bufname)

  -- Markdown syntax for body content
  vim.api.nvim_set_option_value("syntax", "markdown", { buf = bufnr })

  -- Window-local options (applied when buffer is displayed)
  vim.api.nvim_create_autocmd("BufWinEnter", {
    buffer = bufnr,
    once = false,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      vim.api.nvim_set_option_value("conceallevel", 2, { win = win, scope = "local" })
      vim.api.nvim_set_option_value("wrap", true, { win = win, scope = "local" })

      local ui_config = config.values.ui or {}
      if ui_config.use_statuscolumn then
        local statuscolumn = require("bitbucket.ui.statuscolumn")
        vim.api.nvim_set_option_value("statuscolumn", "%!v:lua.require('bitbucket.ui.statuscolumn').statuscolumn()", { win = win, scope = "local" })
        vim.api.nvim_set_option_value("signcolumn", "no", { win = win, scope = "local" })
      elseif ui_config.use_signcolumn ~= false then
        vim.api.nvim_set_option_value("signcolumn", "yes", { win = win, scope = "local" })
      end

      if ui_config.use_foldtext then
        vim.api.nvim_set_option_value("foldtext", "v:lua.require('bitbucket.ui.folds').foldtext()", { win = win, scope = "local" })
        vim.api.nvim_set_option_value("foldmethod", "manual", { win = win, scope = "local" })
      end
    end,
  })
end

-- ============================================================================
-- Rendering
-- ============================================================================

--- Render a pull request to the buffer (octo-style pipeline).
function BitbucketBuffer:render_pull_request()
  local pr = self.node
  if not pr then
    return
  end

  -- Clear buffer
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, {})

  -- Clear all namespaces
  vim.api.nvim_buf_clear_namespace(self.bufnr, constants.HIGHLIGHT_NS, 0, -1)
  vim.api.nvim_buf_clear_namespace(self.bufnr, constants.DETAILS_NS, 0, -1)
  vim.api.nvim_buf_clear_namespace(self.bufnr, constants.COMMENT_NS, 0, -1)
  vim.api.nvim_buf_clear_namespace(self.bufnr, constants.TITLE_VT_NS, 0, -1)
  vim.api.nvim_buf_clear_namespace(self.bufnr, constants.EVENT_VT_NS, 0, -1)
  vim.api.nvim_buf_clear_namespace(self.bufnr, constants.EMPTY_MSG_VT_NS, 0, -1)
  vim.api.nvim_buf_clear_namespace(self.bufnr, constants.DIFFHUNK_VT_NS, 0, -1)

  -- Reset metadata
  self.titleMetadata = nil
  self.bodyMetadata = nil
  self.commentMetadata = {}
  self.metadata.comment_regions = {}

  local line = 0

  -- 1. Title (editable)
  local title_meta
  line, title_meta = writers.write_title(self.bufnr, pr.title or "Untitled", line)
  self.titleMetadata = title_meta

  -- 2. Details (virtual text overlays)
  line = writers.write_details(self.bufnr, pr, line)

  -- 3. State bubble (virtual text on line 0, after title is written)
  writers.write_state(self.bufnr, pr.state or "OPEN", pr.id or 0, pr.draft)

  -- 4. Body (editable)
  local body_meta
  line, body_meta = writers.write_body(self.bufnr, pr.description, line, true)
  self.bodyMetadata = body_meta

  -- 5. Comments
  if self.comments and #self.comments > 0 then
    -- Sort comments: top-level first, then replies
    local top_level = {}
    local replies = {}
    for _, comment in ipairs(self.comments) do
      if comment.parent then
        table.insert(replies, comment)
      else
        table.insert(top_level, comment)
      end
    end

    for _, comment in ipairs(top_level) do
      local kind = comment.inline and "PullRequestReviewComment" or "PullRequestComment"
      local end_line, comment_meta = writers.write_comment(self.bufnr, comment, kind, line)
      line = end_line
      table.insert(self.commentMetadata, comment_meta)

      -- Legacy compat
      table.insert(self.metadata.comment_regions, {
        comment_id = comment.id,
        start_line = comment_meta.startLine,
        end_line = comment_meta.endLine,
        user = comment.user,
      })

      -- Create fold for this comment
      local folds = require("bitbucket.ui.folds")
      folds.create(self.bufnr, comment_meta.startLine, comment_meta.endLine, true)

      -- Write replies for this comment
      for _, reply in ipairs(replies) do
        if reply.parent and reply.parent.id == comment.id then
          local reply_end, reply_meta = writers.write_comment(self.bufnr, reply, "CommentReply", line)
          line = reply_end
          table.insert(self.commentMetadata, reply_meta)
          table.insert(self.metadata.comment_regions, {
            comment_id = reply.id,
            start_line = reply_meta.startLine,
            end_line = reply_meta.endLine,
            user = reply.user,
          })
        end
      end
    end
  end

  -- 6. Timeline events (from activity API)
  if self.activity and type(self.activity) == "table" then
    local activity_values = self.activity.values or self.activity
    if #activity_values > 0 then
      line = writers.write_timeline_items(self.bufnr, activity_values, line)
    end
  end

  -- Set modified to false after render
  vim.api.nvim_set_option_value("modified", false, { buf = self.bufnr })
end

--- Render issue to buffer
function BitbucketBuffer:render_issue()
  local issue = self.node
  if not issue then
    return
  end

  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, false, {})
  vim.api.nvim_buf_clear_namespace(self.bufnr, constants.HIGHLIGHT_NS, 0, -1)
  vim.api.nvim_buf_clear_namespace(self.bufnr, constants.TITLE_VT_NS, 0, -1)

  local line = 0

  -- Title
  local title_meta
  line, title_meta = writers.write_title(self.bufnr, issue.title or "Untitled", line)
  self.titleMetadata = title_meta

  -- State
  local state = issue.state or "open"
  local state_upper = (state == "open" or state == "new") and "OPEN" or "CLOSED"
  writers.write_state(self.bufnr, state_upper, issue.id or 0)

  -- Simple metadata for issues
  local details = { lines = {}, vt = {} }
  local function add(label, value_chunks)
    local TCB = require("bitbucket.ui.text-chunk-builder")
    local builder = TCB.new():detail_label(label)
    local chunks = builder:build()
    for _, chunk in ipairs(value_chunks) do
      table.insert(chunks, chunk)
    end
    table.insert(details.lines, "")
    table.insert(details.vt, chunks)
  end

  if issue.reporter then
    add("Reporter: ", { { issue.reporter.display_name or "Unknown", "BitbucketDetailsValue" } })
  end
  if issue.assignee then
    add("Assignee: ", { { issue.assignee.display_name or "Unassigned", "BitbucketDetailsValue" } })
  end
  add("State: ", { { state, "BitbucketDetailsValue" } })
  if issue.created_on then
    add("Created: ", { { utils.format_relative_time(issue.created_on), "BitbucketDate" } })
  end
  table.insert(details.lines, "")
  table.insert(details.vt, {})

  line = writers.write_detail_table({
    bufnr = self.bufnr,
    ns = constants.DETAILS_NS,
    start_line = line,
    details = details,
  })

  -- Body
  local body_text = issue.content and issue.content.raw or ""
  local body_meta
  line, body_meta = writers.write_body(self.bufnr, body_text, line, true)
  self.bodyMetadata = body_meta

  vim.api.nvim_set_option_value("modified", false, { buf = self.bufnr })
end

--- Render review threads (for thread panel buffers)
function BitbucketBuffer:render_threads()
  -- Will be implemented when thread panel is created
end

-- ============================================================================
-- Metadata & Dirty Tracking
-- ============================================================================

--- Update metadata by reading current buffer content and comparing against saved state.
function BitbucketBuffer:update_metadata()
  local bufnr = self.bufnr

  -- Update title metadata
  if self.titleMetadata and self.titleMetadata.extmark then
    local marks = vim.api.nvim_buf_get_extmarks(bufnr, constants.COMMENT_NS, { 0, 0 }, { -1, -1 }, {
      details = true,
    })
    for _, mark in ipairs(marks) do
      if mark[1] == self.titleMetadata.extmark then
        local start_row = mark[2]
        local end_row = mark[4] and mark[4].end_row or start_row
        local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
        self.titleMetadata.body = vim.trim(table.concat(lines, "\n"))
        self.titleMetadata.dirty = self.titleMetadata:is_dirty()
        self.titleMetadata.startLine = start_row
        self.titleMetadata.endLine = end_row
        break
      end
    end
  end

  -- Update body metadata
  if self.bodyMetadata and self.bodyMetadata.extmark then
    local marks = vim.api.nvim_buf_get_extmarks(bufnr, constants.COMMENT_NS, { 0, 0 }, { -1, -1 }, {
      details = true,
    })
    for _, mark in ipairs(marks) do
      if mark[1] == self.bodyMetadata.extmark then
        local start_row = mark[2]
        local end_row = mark[4] and mark[4].end_row or start_row
        local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
        self.bodyMetadata.body = vim.trim(table.concat(lines, "\n"))
        self.bodyMetadata.dirty = self.bodyMetadata:is_dirty()
        self.bodyMetadata.startLine = start_row
        self.bodyMetadata.endLine = end_row
        break
      end
    end
  end

  -- Update comment metadata
  for _, cm in ipairs(self.commentMetadata) do
    if cm.extmark then
      local marks = vim.api.nvim_buf_get_extmarks(bufnr, constants.COMMENT_NS, { 0, 0 }, { -1, -1 }, {
        details = true,
      })
      for _, mark in ipairs(marks) do
        if mark[1] == cm.extmark then
          local start_row = mark[2]
          local end_row = mark[4] and mark[4].end_row or start_row
          local lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row + 1, false)
          cm.body = vim.trim(table.concat(lines, "\n"))
          cm.dirty = cm:is_dirty()
          cm.startLine = start_row
          cm.endLine = end_row
          break
        end
      end
    end
  end
end

--- Render signs based on dirty state of all tracked regions.
function BitbucketBuffer:render_signs()
  local bufnr = self.bufnr
  signs_mod.unplace_all(bufnr)

  local ui_config = config.values.ui or {}
  local use_statuscolumn = ui_config.use_statuscolumn

  if use_statuscolumn then
    local statuscolumn = require("bitbucket.ui.statuscolumn")
    statuscolumn.remove(bufnr)
  end

  local function place_region_signs(start_line, end_line, is_dirty)
    if use_statuscolumn then
      local statuscolumn = require("bitbucket.ui.statuscolumn")
      statuscolumn.add(bufnr, start_line + 1, end_line + 1, is_dirty)
    else
      -- Use signcolumn
      if start_line == end_line then
        local sign = is_dirty and "dirty_line" or "clean_line"
        -- signs module expects names matching sign definitions
        local sign_name = is_dirty and "dirty_block_middle" or "clean_block_middle"
        signs_mod.place(sign_name, bufnr, start_line + 1)
      else
        local prefix = is_dirty and "dirty" or "clean"
        signs_mod.place(prefix .. "_block_start", bufnr, start_line + 1)
        for l = start_line + 1, end_line - 1 do
          signs_mod.place(prefix .. "_block_middle", bufnr, l + 1)
        end
        signs_mod.place(prefix .. "_block_end", bufnr, end_line + 1)
      end
    end
  end

  -- Title
  if self.titleMetadata then
    place_region_signs(self.titleMetadata.startLine, self.titleMetadata.endLine, self.titleMetadata.dirty)
  end

  -- Body
  if self.bodyMetadata then
    place_region_signs(self.bodyMetadata.startLine, self.bodyMetadata.endLine, self.bodyMetadata.dirty)

    -- Show empty message placeholder if body is empty
    if vim.trim(self.bodyMetadata.body or "") == "" then
      vim.api.nvim_buf_clear_namespace(bufnr, constants.EMPTY_MSG_VT_NS, 0, -1)
      writers.write_virtual_text(bufnr, constants.EMPTY_MSG_VT_NS, self.bodyMetadata.startLine, {
        { "No description provided.", "BitbucketMissingDetails" },
      })
    else
      vim.api.nvim_buf_clear_namespace(bufnr, constants.EMPTY_MSG_VT_NS, 0, -1)
    end
  end

  -- Comments
  for _, cm in ipairs(self.commentMetadata) do
    place_region_signs(cm.startLine, cm.endLine, cm.dirty)
  end
end

-- ============================================================================
-- Save
-- ============================================================================

--- Save dirty regions back to Bitbucket via API.
function BitbucketBuffer:save(callback)
  callback = callback or function() end

  self:update_metadata()

  local api = require("bitbucket.api")
  local pending = 0
  local errors = {}

  local function on_complete()
    pending = pending - 1
    if pending <= 0 then
      if #errors > 0 then
        callback(false, table.concat(errors, "; "))
      else
        -- Mark everything as saved
        if self.titleMetadata then self.titleMetadata:mark_saved() end
        if self.bodyMetadata then self.bodyMetadata:mark_saved() end
        for _, cm in ipairs(self.commentMetadata) do
          cm:mark_saved()
        end
        self:render_signs()
        callback(true, nil)
      end
    end
  end

  -- Check what's dirty
  local title_dirty = self.titleMetadata and self.titleMetadata:is_dirty()
  local body_dirty = self.bodyMetadata and self.bodyMetadata:is_dirty()
  local dirty_comments = {}
  for _, cm in ipairs(self.commentMetadata) do
    if cm:is_dirty() then
      table.insert(dirty_comments, cm)
    end
  end

  if not title_dirty and not body_dirty and #dirty_comments == 0 then
    utils.info("No changes to save")
    callback(true, nil)
    return
  end

  -- Save title and/or body via PR update
  if title_dirty or body_dirty then
    pending = pending + 1
    local update_data = {}
    if title_dirty then
      update_data.title = self.titleMetadata.body
    end
    if body_dirty then
      update_data.description = self.bodyMetadata.body
    end

    api.pullrequests.update({
      workspace = self.workspace,
      repo = self.repo,
      id = self.number,
      data = update_data,
    }, function(success, _, err)
      if not success then
        table.insert(errors, "Failed to update PR: " .. (err or "unknown"))
      end
      on_complete()
    end)
  end

  -- Save dirty comments
  for _, cm in ipairs(dirty_comments) do
    pending = pending + 1
    api.comments.update({
      workspace = self.workspace,
      repo = self.repo,
      id = self.number,
      comment_id = cm.id,
      content = cm.body,
    }, function(success, _, err)
      if not success then
        table.insert(errors, "Failed to update comment " .. tostring(cm.id) .. ": " .. (err or "unknown"))
      end
      on_complete()
    end)
  end

  -- If nothing was async, still complete
  if pending == 0 then
    callback(true, nil)
  end
end

-- ============================================================================
-- Data Loading
-- ============================================================================

function BitbucketBuffer:load_comments(callback)
  callback = callback or function() end

  if self.kind ~= "pull_request" then
    callback()
    return
  end

  local api = require("bitbucket.api")
  api.comments.list({
    workspace = self.workspace,
    repo = self.repo,
    id = self.number,
  }, function(success, data, err)
    if success then
      self.comments = data.values or {}
      utils.debug("Loaded " .. #self.comments .. " comments")
    else
      utils.debug("Failed to load comments: " .. (err or "unknown"))
      self.comments = {}
    end
    callback()
  end)
end

function BitbucketBuffer:load_activity(callback)
  callback = callback or function() end

  if self.kind ~= "pull_request" then
    callback()
    return
  end

  local api = require("bitbucket.api")
  api.comments.get_activity({
    workspace = self.workspace,
    repo = self.repo,
    id = self.number,
  }, function(success, data, err)
    if success then
      self.activity = data
      utils.debug("Loaded activity log")
    else
      utils.debug("Failed to load activity: " .. (err or "unknown"))
      self.activity = nil
    end
    callback()
  end)
end

-- ============================================================================
-- Refresh
-- ============================================================================

function BitbucketBuffer:refresh(callback)
  callback = callback or function() end

  local api = require("bitbucket.api")

  if self.kind == "pull_request" then
    api.pullrequests.get({
      workspace = self.workspace,
      repo = self.repo,
      id = self.number,
    }, function(success, data, err)
      if success then
        self.node = data
        -- Load comments and activity in parallel
        local done_count = 0
        local function check_done()
          done_count = done_count + 1
          if done_count >= 2 then
            self:render_pull_request()
            callback(true, nil)
          end
        end
        self:load_comments(check_done)
        self:load_activity(check_done)
      else
        callback(false, err)
      end
    end)
  elseif self.kind == "issue" then
    api.issues.get({
      workspace = self.workspace,
      repo = self.repo,
      id = self.number,
    }, function(success, data, err)
      if success then
        self.node = data
        self:render_issue()
        callback(true, nil)
      else
        callback(false, err)
      end
    end)
  end
end

-- ============================================================================
-- Helpers
-- ============================================================================

function BitbucketBuffer:add_comment(comment)
  table.insert(self.comments, comment)
  if self.kind == "pull_request" then
    self:render_pull_request()
  end
end

function BitbucketBuffer:destroy()
  _G.bitbucket_buffers[self.bufnr] = nil
  if vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
  end
end

return BitbucketBuffer
