-- TextChunkBuilder: Fluent builder pattern for virtual text chunk arrays (octo.nvim parity)
-- All methods return self for chaining.
-- Usage:
--   local chunks = TextChunkBuilder.new()
--     :timeline_marker("merged")
--     :actor(actor)
--     :text(" merged PR ", "BitbucketTimelineItemHeading")
--     :date(merged_at)
--     :build()
local M = {}

local config = require("bitbucket.config")
local bubbles = require("bitbucket.ui.bubbles")
local constants = require("bitbucket.constants")

---@class TextChunkBuilder
---@field chunks table[]
local TextChunkBuilder = {}
TextChunkBuilder.__index = TextChunkBuilder

--- Create a new builder instance
function M.new()
  local self = setmetatable({}, TextChunkBuilder)
  self.chunks = {}
  return self
end

--- Add a raw text chunk
--- @param text string
--- @param highlight string|nil
--- @return TextChunkBuilder
function TextChunkBuilder:text(text, highlight)
  if text and text ~= "" then
    table.insert(self.chunks, { text, highlight })
  end
  return self
end

--- Add a timeline marker (icon or text bullet)
--- @param icon_name string|nil The timeline icon key from config
--- @param icon_highlight string|nil Override highlight for the icon
--- @return TextChunkBuilder
function TextChunkBuilder:timeline_marker(icon_name, icon_highlight)
  if config.values.use_timeline_icons and icon_name then
    local icon_def = config.values.timeline_icons[icon_name]
    if icon_def then
      local icon, hl
      if type(icon_def) == "table" then
        icon = icon_def[1]
        hl = icon_def[2]
      else
        icon = icon_def
      end
      hl = icon_highlight or hl or "BitbucketTimelineMarker"
      table.insert(self.chunks, { icon .. " ", hl })
      return self
    end
  end

  -- Fallback: use configured timeline_marker
  local marker = config.values.timeline_marker or " "
  table.insert(self.chunks, { marker, icon_highlight or "BitbucketTimelineMarker" })
  return self
end

--- Add an indented timeline marker for nested items
--- @param indent_level number|nil Indentation level (default: 1)
--- @return TextChunkBuilder
function TextChunkBuilder:indented_marker(indent_level)
  indent_level = indent_level or 1
  local indent = config.values.timeline_indent or 2
  local spaces = string.rep(" ", indent * indent_level)
  table.insert(self.chunks, { spaces })
  table.insert(self.chunks, { "├ ", "BitbucketTimelineMarker" })
  return self
end

--- Add a user bubble
--- @param login string Username/display name
--- @param is_viewer boolean Whether this is the current user
--- @param opts table|nil Bubble options
--- @return TextChunkBuilder
function TextChunkBuilder:user(login, is_viewer, opts)
  if login then
    local bubble_chunks = bubbles.make_user_bubble(login, is_viewer, opts)
    for _, chunk in ipairs(bubble_chunks) do
      table.insert(self.chunks, chunk)
    end
  end
  return self
end

--- Add a plain user name (no bubble)
--- @param login string
--- @param is_viewer boolean
--- @return TextChunkBuilder
function TextChunkBuilder:user_plain(login, is_viewer)
  if login then
    local hl = is_viewer and "BitbucketUserViewer" or "BitbucketUser"
    table.insert(self.chunks, { login, hl })
  end
  return self
end

--- Add an actor (shorthand for user_plain with viewer detection)
--- @param actor table Actor object with display_name and optionally uuid
--- @return TextChunkBuilder
function TextChunkBuilder:actor(actor)
  if actor then
    local name = actor.display_name or actor.nickname or "Unknown"
    -- TODO: detect viewer from auth module
    self:user_plain(name, false)
  end
  return self
end

--- Add a label bubble
--- @param name string Label name
--- @param color string Hex color
--- @param opts table|nil
--- @return TextChunkBuilder
function TextChunkBuilder:label(name, color, opts)
  if name then
    local bubble_chunks = bubbles.make_label_bubble(name, color, opts)
    for _, chunk in ipairs(bubble_chunks) do
      table.insert(self.chunks, chunk)
    end
  end
  return self
end

--- Add a state bubble
--- @param state string State text (e.g. "OPEN", "MERGED")
--- @param state_highlight string Highlight group for the state
--- @return TextChunkBuilder
function TextChunkBuilder:state_bubble(state, state_highlight)
  if state then
    local bubble_hl = (state_highlight or "BitbucketBubble"):gsub("Bitbucket", "BitbucketBubble")
    -- Try to find matching bubble highlight, fallback to body
    local body_hl = state_highlight and (state_highlight .. "Bubble")
    if not body_hl or vim.fn.hlexists(body_hl) == 0 then
      body_hl = "BitbucketBubble"
    end
    local bubble_chunks = bubbles.make_bubble(state, body_hl)
    for _, chunk in ipairs(bubble_chunks) do
      table.insert(self.chunks, chunk)
    end
  end
  return self
end

--- Add a generic bubble
--- @param content string
--- @param highlight string
--- @return TextChunkBuilder
function TextChunkBuilder:bubble(content, highlight)
  if content then
    local bubble_chunks = bubbles.make_bubble(content, highlight or "BitbucketBubble")
    for _, chunk in ipairs(bubble_chunks) do
      table.insert(self.chunks, chunk)
    end
  end
  return self
end

--- Add a heading-styled text
--- @param text string
--- @return TextChunkBuilder
function TextChunkBuilder:heading(text)
  if text then
    table.insert(self.chunks, { text, "BitbucketTimelineItemHeading" })
  end
  return self
end

--- Add a formatted date
--- @param date_str string ISO 8601 date string
--- @return TextChunkBuilder
function TextChunkBuilder:date(date_str)
  if date_str then
    local formatted = require("bitbucket.utils").format_relative_time(date_str)
    table.insert(self.chunks, { formatted, "BitbucketDate" })
  end
  return self
end

--- Add a lock icon when the user cannot update
--- @param viewer_can_update boolean
--- @return TextChunkBuilder
function TextChunkBuilder:lock_icon(viewer_can_update)
  if not viewer_can_update then
    table.insert(self.chunks, { " ", "BitbucketGrey" })
  end
  return self
end

--- Conditional text: only adds if condition is true
--- @param condition boolean
--- @param text string
--- @param highlight string|nil
--- @return TextChunkBuilder
function TextChunkBuilder:when(condition, text, highlight)
  if condition and text then
    table.insert(self.chunks, { text, highlight })
  end
  return self
end

--- Conditional callback: calls fn(self) if condition is true
--- @param condition boolean
--- @param callback function(self: TextChunkBuilder)
--- @return TextChunkBuilder
function TextChunkBuilder:when_fn(condition, callback)
  if condition and callback then
    callback(self)
  end
  return self
end

--- Add a detail label (left column of detail table)
--- @param label_text string
--- @return TextChunkBuilder
function TextChunkBuilder:detail_label(label_text)
  table.insert(self.chunks, { label_text, "BitbucketDetailsLabel" })
  return self
end

--- Add a detail value (right column of detail table)
--- @param value string
--- @return TextChunkBuilder
function TextChunkBuilder:detail_value(value)
  table.insert(self.chunks, { value, "BitbucketDetailsValue" })
  return self
end

--- Add a missing detail placeholder
--- @param value string
--- @return TextChunkBuilder
function TextChunkBuilder:detail_missing(value)
  table.insert(self.chunks, { value, "BitbucketMissingDetails" })
  return self
end

--- Add a state indicator with icon and optional draft marker
--- @param state string PR state (OPEN, MERGED, DECLINED, etc.)
--- @param is_draft boolean|nil
--- @return TextChunkBuilder
function TextChunkBuilder:state_with_icon(state, is_draft)
  local state_upper = (state or "OPEN"):upper()
  local display_state = state_upper
  local state_hl

  if is_draft then
    display_state = "DRAFT"
    state_hl = "BitbucketStateDraft"
  elseif state_upper == "OPEN" then
    state_hl = "BitbucketStateOpen"
  elseif state_upper == "MERGED" then
    state_hl = "BitbucketStateMerged"
  elseif state_upper == "DECLINED" or state_upper == "CLOSED" then
    state_hl = "BitbucketStateClosed"
  elseif state_upper == "SUPERSEDED" then
    state_hl = "BitbucketStateClosed"
  else
    state_hl = "BitbucketStateOpen"
  end

  -- Build bubble for state
  local bubble_hl = state_hl .. "Bubble"
  if vim.fn.hlexists(bubble_hl) == 0 then
    bubble_hl = "BitbucketBubble"
  end

  local bubble_chunks = bubbles.make_bubble(" " .. display_state .. " ", bubble_hl, { margin_width = 1 })
  for _, chunk in ipairs(bubble_chunks) do
    table.insert(self.chunks, chunk)
  end

  return self
end

-- Output methods

--- Return the built chunks array
--- @return table[]
function TextChunkBuilder:build()
  return self.chunks
end

--- Write chunks as virtual text (overlay) at a specific line
--- @param bufnr number
--- @param ns number Namespace ID
--- @param line number 0-indexed line number
function TextChunkBuilder:write(bufnr, ns, line)
  if #self.chunks > 0 then
    vim.api.nvim_buf_set_extmark(bufnr, ns, line, 0, {
      virt_text = self.chunks,
      virt_text_pos = "overlay",
      hl_mode = "combine",
    })
  end
end

--- Write chunks as a timeline event (with spacing)
--- @param bufnr number
--- @return number The line after the event
function TextChunkBuilder:write_event(bufnr)
  if #self.chunks == 0 then
    return vim.api.nvim_buf_line_count(bufnr)
  end

  local line = vim.api.nvim_buf_line_count(bufnr)

  -- Insert an empty line for the event
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, { "" })

  -- Write the virtual text on that line
  vim.api.nvim_buf_set_extmark(bufnr, constants.EVENT_VT_NS, line, 0, {
    virt_text = self.chunks,
    virt_text_pos = "overlay",
    hl_mode = "combine",
  })

  return line + 1
end

--- Append chunks as a detail line to a details table
--- @param details table The details accumulator table { lines = {}, vt = {} }
function TextChunkBuilder:write_detail_line(details)
  table.insert(details.lines, "")
  table.insert(details.vt, self.chunks)
end

return M
