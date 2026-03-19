-- Window management module (octo.nvim parity)
-- Centralized functions for creating floating windows, centered floats, and popups.
local M = {}

--- Create a generic floating window with proper border detection.
--- @param opts table|nil Options: width, height, col, row, bufnr, border, title, title_pos, focusable
--- @return table { bufnr: number, winnr: number }
function M.create_floating_window(opts)
  opts = opts or {}

  local bufnr = opts.bufnr or vim.api.nvim_create_buf(false, true)

  local width = opts.width or math.floor(vim.o.columns * 0.8)
  local height = opts.height or math.floor(vim.o.lines * 0.6)
  local col = opts.col or math.floor((vim.o.columns - width) / 2)
  local row = opts.row or math.floor((vim.o.lines - height) / 2)

  -- Detect border style
  local border = opts.border
  if border == nil then
    -- Use vim.o.winborder if available (nvim 0.10+), else "rounded"
    if vim.o.winborder and vim.o.winborder ~= "" then
      border = vim.o.winborder
    else
      border = "rounded"
    end
  end

  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = border,
    focusable = opts.focusable ~= false,
  }

  if opts.title then
    win_opts.title = opts.title
    win_opts.title_pos = opts.title_pos or "center"
  end

  local winnr = vim.api.nvim_open_win(bufnr, true, win_opts)

  -- Disable UI clutter in the float
  vim.api.nvim_set_option_value("foldcolumn", "0", { win = winnr, scope = "local" })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = winnr, scope = "local" })
  vim.api.nvim_set_option_value("number", false, { win = winnr, scope = "local" })
  vim.api.nvim_set_option_value("relativenumber", false, { win = winnr, scope = "local" })
  vim.api.nvim_set_option_value("cursorline", false, { win = winnr, scope = "local" })

  return { bufnr = bufnr, winnr = winnr }
end

--- Create a centered floating window with content-aware sizing.
--- If content is provided, auto-sizes to fit. Otherwise uses percentage-based sizing.
--- @param opts table|nil Options: content (string[]), header (string), pct_width (0-1), pct_height (0-1), syntax, bufnr
--- @return table { bufnr: number, winnr: number }
function M.create_centered_float(opts)
  opts = opts or {}

  local content = opts.content
  local width, height

  if content and #content > 0 then
    -- Auto-size to content
    local max_width = 0
    for _, line in ipairs(content) do
      max_width = math.max(max_width, vim.fn.strdisplaywidth(line))
    end
    width = math.min(max_width + 4, vim.o.columns - 4)
    height = math.min(#content + 2, vim.o.lines - 4)
  else
    -- Percentage-based sizing
    local pct_w = opts.pct_width or 0.6
    local pct_h = opts.pct_height or 0.4
    width = math.floor(vim.o.columns * pct_w)
    height = math.floor(vim.o.lines * pct_h)
  end

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)

  local float = M.create_floating_window({
    bufnr = opts.bufnr,
    width = width,
    height = height,
    col = col,
    row = row,
    title = opts.header,
    title_pos = "center",
  })

  -- Set content if provided
  if content then
    vim.api.nvim_buf_set_lines(float.bufnr, 0, -1, false, content)
  end

  -- Set syntax if requested
  if opts.syntax then
    vim.api.nvim_set_option_value("syntax", opts.syntax, { buf = float.bufnr })
  end

  return float
end

--- Create a cursor-relative popup window with auto-close behavior.
--- Used for user profile hovers, reaction details, etc.
--- @param opts table Options: content (string[]), width, height, border
--- @return table { bufnr: number, winnr: number }
function M.create_popup(opts)
  opts = opts or {}

  local content = opts.content or {}
  local width = opts.width
  local height = opts.height

  -- Auto-size from content
  if not width then
    local max_width = 0
    for _, line in ipairs(content) do
      max_width = math.max(max_width, vim.fn.strdisplaywidth(line))
    end
    width = math.min(max_width + 2, math.floor(vim.o.columns * 0.5))
  end
  if not height then
    height = math.min(#content, math.floor(vim.o.lines * 0.3))
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, content)

  local win_opts = {
    relative = "cursor",
    width = width,
    height = height,
    col = 0,
    row = 1,
    anchor = "NW",
    style = "minimal",
    border = opts.border or "rounded",
    focusable = false,
  }

  local winnr = vim.api.nvim_open_win(bufnr, false, win_opts)

  -- Disable UI clutter
  vim.api.nvim_set_option_value("foldcolumn", "0", { win = winnr, scope = "local" })
  vim.api.nvim_set_option_value("signcolumn", "no", { win = winnr, scope = "local" })
  vim.api.nvim_set_option_value("number", false, { win = winnr, scope = "local" })
  vim.api.nvim_set_option_value("wrap", true, { win = winnr, scope = "local" })

  -- Auto-close on cursor movement
  local augroup = vim.api.nvim_create_augroup("BitbucketPopup_" .. winnr, { clear = true })
  local function close()
    if vim.api.nvim_win_is_valid(winnr) then
      vim.api.nvim_win_close(winnr, true)
    end
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
    pcall(vim.api.nvim_del_augroup_by_id, augroup)
  end

  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "WinLeave", "BufLeave" }, {
    group = augroup,
    callback = function()
      vim.schedule(close)
    end,
    once = true,
  })

  return { bufnr = bufnr, winnr = winnr }
end

return M
