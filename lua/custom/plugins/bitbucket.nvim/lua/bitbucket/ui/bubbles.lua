-- Bubble UI components (octo.nvim parity)
-- Bubbles are pill-shaped UI elements used for labels, users, states, and reactions.
-- Each bubble consists of 3 virtual text chunks:
--   1. Left delimiter (fg-only hl matching bubble bg)
--   2. Body content (colored bg)
--   3. Right delimiter (fg-only hl matching bubble bg)
local M = {}

local config = require("bitbucket.config")
local colors = require("bitbucket.ui.colors")

--- Build margin/padding strings from options
local function get_spacing(opts)
  opts = opts or {}
  local left_margin = string.rep(" ", opts.left_margin_width or opts.margin_width or 0)
  local right_margin = string.rep(" ", opts.right_margin_width or opts.margin_width or 0)
  local left_padding = string.rep(" ", opts.left_padding_width or opts.padding_width or 0)
  local right_padding = string.rep(" ", opts.right_padding_width or opts.padding_width or 0)
  return left_margin, right_margin, left_padding, right_padding
end

--- Get the background color hex string from a highlight group name.
--- Returns nil if the group doesn't exist or has no bg.
local function get_hl_bg_hex(hl_group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = hl_group, link = false })
  if ok and hl and hl.bg then
    return string.format("#%06x", hl.bg)
  end
  return nil
end

--- Create a generic bubble (pill-shaped badge).
--- @param content string The text inside the bubble
--- @param highlight_group string The highlight group for the body (must have a bg color)
--- @param opts table|nil Options: margin_width, padding_width, etc.
--- @return table[] Virtual text chunks array
function M.make_bubble(content, highlight_group, opts)
  opts = opts or {}
  local left_margin, right_margin, left_padding, right_padding = get_spacing(opts)

  local left_delim = config.values.left_bubble_delimiter or ""
  local right_delim = config.values.right_bubble_delimiter or ""

  -- Get the bg color of the body highlight to use as fg for delimiters
  local bg_hex = get_hl_bg_hex(highlight_group)
  local delimiter_hl
  if bg_hex then
    delimiter_hl = colors.create_highlight(bg_hex, { mode = "foreground" })
  else
    delimiter_hl = highlight_group
  end

  local chunks = {}

  -- Left margin
  if left_margin ~= "" then
    table.insert(chunks, { left_margin })
  end

  -- Left delimiter
  table.insert(chunks, { left_delim, delimiter_hl })

  -- Body
  table.insert(chunks, { left_padding .. content .. right_padding, highlight_group })

  -- Right delimiter
  table.insert(chunks, { right_delim, delimiter_hl })

  -- Right margin
  if right_margin ~= "" then
    table.insert(chunks, { right_margin })
  end

  return chunks
end

--- Create a user bubble.
--- @param name string The user's display name
--- @param is_viewer boolean Whether this is the current/viewer user
--- @param opts table|nil Options
--- @return table[] Virtual text chunks array
function M.make_user_bubble(name, is_viewer, opts)
  opts = opts or {}
  local user_icon = config.values.user_icon or " "
  local hl = is_viewer and "BitbucketViewer" or "BitbucketUser"

  -- For users, the bubble is: icon + name
  local content = user_icon .. name

  -- Use the Bubble/Viewer highlight as body
  local body_hl = is_viewer and "BitbucketViewer" or "BitbucketBubble"

  return M.make_bubble(content, body_hl, opts)
end

--- Create a label bubble with an arbitrary hex color.
--- @param name string The label name
--- @param color string Hex color code (e.g., "#ff0000")
--- @param opts table|nil Options
--- @return table[] Virtual text chunks array
function M.make_label_bubble(name, color, opts)
  opts = opts or {}

  -- GitHub-style color name lookup (for Bitbucket label colors)
  local color_lookup = {
    GRAY = "#666666",
    BLUE = "#0052CC",
    GREEN = "#36B37E",
    YELLOW = "#FF991F",
    RED = "#FF5630",
    PURPLE = "#6554C0",
    TEAL = "#00B8D9",
  }

  local hex = color_lookup[color] or color or "#666666"
  local body_hl = colors.create_highlight(hex, { mode = "background" })

  return M.make_bubble(name, body_hl, opts)
end

return M
