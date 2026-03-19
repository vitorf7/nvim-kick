-- Review Layout management (octo.nvim parity)
-- Manages the tabpage-based diff review interface: left/right splits + file panel.
local M = {}

local config = require("bitbucket.config")
local constants = require("bitbucket.constants")

---@class ReviewLayout
---@field tabnr number
---@field file_panel_win number
---@field file_panel_buf number
---@field left_win number
---@field left_buf number
---@field right_win number
---@field right_buf number
local Layout = {}
Layout.__index = Layout

function M.new()
  return setmetatable({}, Layout)
end

--- Initialize the 3-panel layout in a new tab.
function Layout:init_layout()
  -- Create new tab for review isolation
  vim.cmd("tabnew")
  self.tabnr = vim.api.nvim_get_current_tabpage()

  -- File panel (left, 40 columns)
  vim.cmd("topleft vsplit")
  self.file_panel_win = vim.api.nvim_get_current_win()
  self.file_panel_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(self.file_panel_win, self.file_panel_buf)
  vim.api.nvim_win_set_width(self.file_panel_win, 40)

  -- File panel buffer options
  vim.api.nvim_set_option_value("filetype", "bitbucket-review-panel", { buf = self.file_panel_buf })
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = self.file_panel_buf })
  vim.api.nvim_set_option_value("swapfile", false, { buf = self.file_panel_buf })
  pcall(vim.api.nvim_buf_set_name, self.file_panel_buf, "Bitbucket Review - Files")

  -- File panel window options (octo-style)
  local panel_opts = {
    relativenumber = false,
    number = false,
    list = false,
    winfixwidth = true,
    winfixheight = true,
    cursorline = true,
    cursorlineopt = "line",
    signcolumn = "yes",
    foldcolumn = "0",
    scrollbind = false,
    cursorbind = false,
    diff = false,
  }
  for k, v in pairs(panel_opts) do
    vim.api.nvim_set_option_value(k, v, { win = self.file_panel_win, scope = "local" })
  end

  -- File panel window highlights (octo-style)
  vim.api.nvim_set_option_value("winhl",
    table.concat({
      "EndOfBuffer:BitbucketEndOfBuffer",
      "Normal:BitbucketNormal",
      "WinSeparator:BitbucketWinSeparator",
      "SignColumn:BitbucketNormal",
      "StatusLine:BitbucketStatusLine",
      "StatusLineNC:BitbucketStatusLineNC",
    }, ","),
    { win = self.file_panel_win })

  -- Left diff window (middle)
  vim.cmd("wincmd l")
  self.left_win = vim.api.nvim_get_current_win()
  self.left_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(self.left_win, self.left_buf)

  -- Left window: deletions highlighted (purple tint)
  vim.api.nvim_win_set_hl_ns(self.left_win, constants.REVIEW_LEFT_NS)
  vim.api.nvim_set_hl(constants.REVIEW_LEFT_NS, "DiffText", { bg = "#5d425a" })
  vim.api.nvim_set_hl(constants.REVIEW_LEFT_NS, "DiffChange", { link = "DiffDelete" })

  -- Right diff window
  vim.cmd("belowright vsp")
  self.right_win = vim.api.nvim_get_current_win()
  self.right_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(self.right_win, self.right_buf)

  -- Right window: additions highlighted (blue tint)
  vim.api.nvim_win_set_hl_ns(self.right_win, constants.REVIEW_RIGHT_NS)
  vim.api.nvim_set_hl(constants.REVIEW_RIGHT_NS, "DiffText", { bg = "#39556f" })
  vim.api.nvim_set_hl(constants.REVIEW_RIGHT_NS, "DiffChange", { link = "DiffAdd" })

  -- Buffer options for diff buffers
  for _, buf in ipairs({ self.left_buf, self.right_buf }) do
    vim.api.nvim_set_option_value("filetype", "bitbucket-review", { buf = buf })
    vim.api.nvim_set_option_value("buftype", "nofile", { buf = buf })
    vim.api.nvim_set_option_value("swapfile", false, { buf = buf })
    vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
  end

  -- Left buffer: nofile to prevent LSP attachment
  vim.api.nvim_set_option_value("buftype", "nofile", { buf = self.left_buf })

  -- Window options for diff views (octo-style)
  local diff_opts = {
    foldmethod = "diff",
    foldlevel = 0,
    cursorlineopt = "number",
    scrollbind = true,
    cursorbind = true,
  }
  for _, win in ipairs({ self.left_win, self.right_win }) do
    for k, v in pairs(diff_opts) do
      vim.api.nvim_set_option_value(k, v, { win = win, scope = "local" })
    end
  end
end

--- Set the current file in the diff view.
--- @param file table File data with hunks
--- @param focus string|nil "left" or "right" (default from config)
function Layout:set_current_file(file, focus)
  focus = focus or (config.values.reviews and config.values.reviews.focus) or "right"

  -- Focus the configured side
  if focus == "left" and vim.api.nvim_win_is_valid(self.left_win) then
    vim.api.nvim_set_current_win(self.left_win)
  elseif vim.api.nvim_win_is_valid(self.right_win) then
    vim.api.nvim_set_current_win(self.right_win)
  end
end

--- Validate that all windows are still valid. Recover if not.
--- @return boolean valid Whether the layout is intact
function Layout:ensure_layout()
  local valid = true

  if not vim.api.nvim_tabpage_is_valid(self.tabnr) then
    return false
  end

  if not vim.api.nvim_win_is_valid(self.file_panel_win) then
    valid = false
  end
  if not vim.api.nvim_win_is_valid(self.left_win) then
    valid = false
  end
  if not vim.api.nvim_win_is_valid(self.right_win) then
    valid = false
  end

  return valid
end

--- Close the layout and clean up.
function Layout:close()
  if self.tabnr and vim.api.nvim_tabpage_is_valid(self.tabnr) then
    pcall(vim.cmd, "tabclose " .. vim.api.nvim_tabpage_get_number(self.tabnr))
  end
end

return M
