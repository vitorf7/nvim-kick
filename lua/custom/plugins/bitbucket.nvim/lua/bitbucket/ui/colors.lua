local M = {}
local config = require("bitbucket.config")

-- Default color values (aligned with octo.nvim)
local default_colors = {
  white = "#ffffff",
  grey = "#2A354C",
  black = "#000000",
  red = "#fdb8c0",
  dark_red = "#fdb8c0",
  green = "#acf2bd",
  dark_green = "#acf2bd",
  yellow = "#d3c846",
  dark_yellow = "#735c0f",
  blue = "#58A6FF",
  dark_blue = "#58A6FF",
  purple = "#6f42c1",
}

-- Get color from config or defaults
local function get_colors()
  return vim.tbl_deep_extend("force", default_colors, config.values.colors or {})
end

-- Get foreground color from a highlight group
local function get_fg(hl_group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = hl_group, link = false })
  if ok and hl and hl.fg then
    return string.format("#%06x", hl.fg)
  end
  return nil
end

-- Get background color from a highlight group
local function get_bg(hl_group)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = hl_group, link = false })
  if ok and hl and hl.bg then
    return string.format("#%06x", hl.bg)
  end
  return nil
end

-- Cache for dynamically created highlights
local HIGHLIGHT_CACHE = {}

-- Calculate relative luminance of a hex color
local function luminance(hex)
  hex = hex:gsub("#", "")
  local r = tonumber(hex:sub(1, 2), 16) / 255
  local g = tonumber(hex:sub(3, 4), 16) / 255
  local b = tonumber(hex:sub(5, 6), 16) / 255

  -- sRGB to linear
  r = r <= 0.03928 and r / 12.92 or ((r + 0.055) / 1.055) ^ 2.4
  g = g <= 0.03928 and g / 12.92 or ((g + 0.055) / 1.055) ^ 2.4
  b = b <= 0.03928 and b / 12.92 or ((b + 0.055) / 1.055) ^ 2.4

  return 0.2126 * r + 0.7152 * g + 0.0722 * b
end

--- Create a highlight group dynamically from a hex color code.
--- Used for label bubbles with arbitrary colors.
--- @param rgb_hex string The hex color code (e.g., "#ff0000")
--- @param options table|nil Options: { mode = "background"|"foreground" }
--- @return string The highlight group name
function M.create_highlight(rgb_hex, options)
  options = options or {}
  local mode = options.mode or "background"

  if not rgb_hex or rgb_hex == "" then
    return "BitbucketBubble"
  end

  -- Normalize hex
  rgb_hex = rgb_hex:gsub("#", "")
  if #rgb_hex ~= 6 then
    return "BitbucketBubble"
  end

  local cache_key = rgb_hex .. "_" .. mode
  if HIGHLIGHT_CACHE[cache_key] then
    return HIGHLIGHT_CACHE[cache_key]
  end

  local hl_name
  if mode == "background" then
    hl_name = "BitbucketBubbleBg_" .. rgb_hex
    -- Pick black or white foreground based on luminance
    local lum = luminance(rgb_hex)
    local fg = lum > 0.5 and "#000000" or "#ffffff"
    vim.api.nvim_set_hl(0, hl_name, { fg = fg, bg = "#" .. rgb_hex, bold = true })
  else
    hl_name = "BitbucketBubbleFg_" .. rgb_hex
    vim.api.nvim_set_hl(0, hl_name, { fg = "#" .. rgb_hex })
  end

  HIGHLIGHT_CACHE[cache_key] = hl_name
  return hl_name
end

-- Setup highlight groups (octo.nvim parity)
function M.setup()
  local colors = get_colors()

  -- Helper function to set highlights only if not user-overridden
  local function set_hl(name, opts)
    if vim.fn.hlexists(name) == 0 then
      vim.api.nvim_set_hl(0, name, opts)
    end
  end

  local function set_hl_link(from, to)
    if vim.fn.hlexists(from) == 0 then
      vim.api.nvim_set_hl(0, from, { link = to })
    end
  end

  -- Basic colors (used as base for other highlights)
  set_hl("BitbucketGreen", { fg = colors.dark_green })
  set_hl("BitbucketRed", { fg = colors.dark_red })
  set_hl("BitbucketPurple", { fg = colors.purple })
  set_hl("BitbucketYellow", { fg = colors.yellow })
  set_hl("BitbucketBlue", { fg = colors.blue })
  set_hl("BitbucketGrey", { fg = colors.grey })

  -- Float variants (with background for floating windows)
  local float_bg = get_bg("NormalFloat") or colors.grey
  set_hl("BitbucketGreenFloat", { fg = colors.dark_green, bg = float_bg })
  set_hl("BitbucketRedFloat", { fg = colors.dark_red, bg = float_bg })
  set_hl("BitbucketPurpleFloat", { fg = colors.purple, bg = float_bg })
  set_hl("BitbucketYellowFloat", { fg = colors.yellow, bg = float_bg })
  set_hl("BitbucketBlueFloat", { fg = colors.blue, bg = float_bg })

  -- Bubble highlights (filled background style for bubble bodies)
  set_hl("BitbucketBubbleGreen", { fg = colors.white, bg = colors.dark_green, bold = true })
  set_hl("BitbucketBubbleRed", { fg = colors.white, bg = colors.dark_red, bold = true })
  set_hl("BitbucketBubblePurple", { fg = colors.white, bg = colors.purple, bold = true })
  set_hl("BitbucketBubbleYellow", { fg = colors.black, bg = colors.yellow, bold = true })
  set_hl("BitbucketBubbleBlue", { fg = colors.white, bg = colors.dark_blue, bold = true })
  set_hl("BitbucketBubbleGrey", { fg = colors.white, bg = colors.grey, bold = true })

  -- Bubble delimiter highlights (foreground-only, for rounded edges)
  set_hl("BitbucketBubbleDelimiterGreen", { fg = colors.dark_green })
  set_hl("BitbucketBubbleDelimiterRed", { fg = colors.dark_red })
  set_hl("BitbucketBubbleDelimiterPurple", { fg = colors.purple })
  set_hl("BitbucketBubbleDelimiterYellow", { fg = colors.dark_yellow })
  set_hl("BitbucketBubbleDelimiterBlue", { fg = colors.dark_blue })
  set_hl("BitbucketBubbleDelimiterGrey", { fg = colors.grey })

  -- Default bubble (white on grey)
  set_hl("BitbucketBubble", { fg = colors.white, bg = colors.grey, bold = true })

  -- UI element highlights
  set_hl_link("BitbucketNormal", "Normal")
  set_hl_link("BitbucketCursorLine", "CursorLine")
  set_hl_link("BitbucketWinSeparator", "WinSeparator")
  set_hl_link("BitbucketSignColumn", "SignColumn")
  set_hl_link("BitbucketStatusColumn", "SignColumn")
  set_hl_link("BitbucketStatusLine", "StatusLine")
  set_hl_link("BitbucketStatusLineNC", "StatusLineNC")
  set_hl_link("BitbucketEndOfBuffer", "EndOfBuffer")

  -- User and metadata highlights
  set_hl("BitbucketUser", { fg = colors.blue, bold = true })
  set_hl("BitbucketUserViewer", { fg = colors.blue, bold = true })
  set_hl("BitbucketDate", { fg = colors.grey, italic = true })
  set_hl("BitbucketLabel", { fg = colors.blue, bg = colors.dark_blue, bold = true })
  set_hl("BitbucketLink", { fg = colors.blue, underline = true })
  set_hl("BitbucketTitle", { fg = colors.white, bold = true })
  set_hl("BitbucketSectionHeader", { fg = colors.blue, bold = true })

  -- Octo-parity highlights
  set_hl_link("BitbucketIssueTitle", "PreProc")
  set_hl_link("BitbucketIssueId", "NormalFloat")
  set_hl_link("BitbucketTimelineItemHeading", "Comment")
  set_hl_link("BitbucketTimelineMarker", "Identifier")

  -- Viewer highlight (octo-style: black on blue)
  set_hl("BitbucketViewer", { fg = colors.black, bg = colors.blue })

  -- Details table (octo-style links)
  set_hl_link("BitbucketDetailsLabel", "Title")
  set_hl_link("BitbucketDetailsValue", "Identifier")
  set_hl_link("BitbucketMissingDetails", "Comment")

  -- State highlights (with links)
  set_hl_link("BitbucketStateOpen", "BitbucketGreen")
  set_hl_link("BitbucketStateClosed", "BitbucketRed")
  set_hl_link("BitbucketStateMerged", "BitbucketPurple")
  set_hl_link("BitbucketStateDraft", "BitbucketGrey")
  set_hl_link("BitbucketStateApproved", "BitbucketGreen")
  set_hl_link("BitbucketStateChangesRequested", "BitbucketRed")
  set_hl_link("BitbucketStatePending", "BitbucketYellow")
  set_hl_link("BitbucketStateDeclined", "BitbucketRed")
  set_hl_link("BitbucketStateSubmitted", "BitbucketBlue")
  set_hl_link("BitbucketStateCommented", "BitbucketBlue")
  set_hl_link("BitbucketStateDismissed", "BitbucketGrey")

  -- State bubble variants (for bubble bodies)
  set_hl_link("BitbucketStateOpenBubble", "BitbucketBubbleGreen")
  set_hl_link("BitbucketStateClosedBubble", "BitbucketBubbleRed")
  set_hl_link("BitbucketStateMergedBubble", "BitbucketBubblePurple")
  set_hl_link("BitbucketStateDraftBubble", "BitbucketBubbleGrey")
  set_hl_link("BitbucketStatePendingBubble", "BitbucketBubbleYellow")
  set_hl_link("BitbucketStateApprovedBubble", "BitbucketBubbleGreen")
  set_hl_link("BitbucketStateChangesRequestedBubble", "BitbucketBubbleRed")

  -- State float variants
  set_hl_link("BitbucketStateOpenFloat", "BitbucketGreenFloat")
  set_hl_link("BitbucketStateClosedFloat", "BitbucketRedFloat")
  set_hl_link("BitbucketStateMergedFloat", "BitbucketPurpleFloat")
  set_hl_link("BitbucketStateDraftFloat", "BitbucketBlueFloat")

  -- Dirty indicator (for modified editable regions)
  set_hl_link("BitbucketDirty", "BitbucketRed")

  -- File status highlights
  set_hl_link("BitbucketStatusAdded", "BitbucketGreen")
  set_hl_link("BitbucketStatusDeleted", "BitbucketRed")
  set_hl_link("BitbucketStatusModified", "BitbucketBlue")
  set_hl_link("BitbucketStatusRenamed", "BitbucketBlue")
  set_hl_link("BitbucketStatusCopied", "BitbucketGreen")
  set_hl_link("BitbucketStatusUnmerged", "BitbucketRed")

  -- Diff highlights
  set_hl_link("BitbucketDiffAdd", "DiffAdd")
  set_hl_link("BitbucketDiffDelete", "DiffDelete")
  set_hl_link("BitbucketDiffChange", "DiffChange")
  set_hl_link("BitbucketDiffText", "DiffText")

  -- Pull stats highlights (octo-style)
  set_hl_link("BitbucketPullAdditions", "BitbucketGreen")
  set_hl_link("BitbucketPullDeletions", "BitbucketRed")
  set_hl_link("BitbucketDiffstatAdditions", "BitbucketGreen")
  set_hl_link("BitbucketDiffstatDeletions", "BitbucketRed")
  set_hl_link("BitbucketDiffstatNeutral", "BitbucketGrey")

  -- Comments
  set_hl_link("BitbucketComment", "Normal")
  set_hl("BitbucketThread", { bg = colors.grey })
  set_hl("BitbucketCommentAuthor", { fg = colors.blue, bold = true })
  set_hl("BitbucketCommentHeader", { fg = colors.grey, italic = true })

  -- Review
  set_hl_link("BitbucketReviewComment", "Comment")
  set_hl("BitbucketReviewThread", { bg = colors.grey })
  set_hl("BitbucketReviewAdd", { fg = colors.dark_green, bg = colors.green })
  set_hl("BitbucketReviewDelete", { fg = colors.dark_red, bg = colors.red })
  set_hl("BitbucketReviewChange", { fg = colors.dark_yellow, bg = colors.yellow })

  -- File panel (octo-style)
  local dir_fg = get_fg("Directory") or colors.blue
  local ident_fg = get_fg("Identifier") or colors.purple
  set_hl("BitbucketFilePanelTitle", { fg = dir_fg, bold = true })
  set_hl("BitbucketFilePanelCounter", { fg = ident_fg, bold = true })
  set_hl("BitbucketFilePanelFileName", { fg = colors.white, bold = true })
  set_hl("BitbucketFilePanelPath", { fg = colors.grey })
  set_hl("BitbucketFilePanelSelected", { bg = colors.dark_blue })
  set_hl("BitbucketFilePanelViewed", { fg = colors.dark_green })

  -- Editable areas
  set_hl("BitbucketEditable", { bg = float_bg })

  -- Text decoration highlights
  set_hl("BitbucketStrikethrough", { fg = colors.grey, strikethrough = true })
  set_hl("BitbucketUnderline", { fg = colors.white, underline = true })
end

-- Get a highlight color
function M.get_color(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if ok and hl then
    return hl
  end
  return nil
end

-- Get all configured colors
function M.get_colors()
  return get_colors()
end

return M
