local M = {}
local constants = require("bitbucket.constants")
local utils = require("bitbucket.utils")
local config = require("bitbucket.config")

-- Setup autocommands
function M.setup()
  local group = vim.api.nvim_create_augroup("Bitbucket", { clear = true })
  
  -- Filetype settings for bitbucket buffers
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = { constants.BUFFER_FILETYPE, constants.REVIEW_FILETYPE, "bitbucket-review-panel" },
    callback = function(args)
      M.setup_buffer(args.buf)
    end,
  })
  
  -- Auto-save on buffer write
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    group = group,
    pattern = "bitbucket://*",
    callback = function(args)
      M.save_buffer(args.buf)
    end,
  })
  
  -- Clean up on buffer delete
  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    pattern = "bitbucket://*",
    callback = function(args)
      M.cleanup_buffer(args.buf)
    end,
  })
  
  -- Refresh on focus
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    pattern = "bitbucket://*",
    callback = function(args)
      M.on_buffer_enter(args.buf)
    end,
  })

  -- Update metadata and signs on text changes (for dirty tracking)
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
    group = group,
    pattern = "bitbucket://*",
    callback = function(args)
      local buffer = _G.bitbucket_buffers[args.buf]
      if buffer and buffer.update_metadata then
        buffer:update_metadata()
        buffer:render_signs()
      end
    end,
  })
end

-- Setup buffer options and mappings
function M.setup_buffer(bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, "filetype")
  
  -- Buffer options
  vim.api.nvim_buf_set_option(bufnr, "buftype", "acwrite")
  vim.api.nvim_buf_set_option(bufnr, "bufhidden", "hide")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
  
  -- Enable markdown syntax
  if ft == constants.BUFFER_FILETYPE then
    vim.api.nvim_buf_set_option(bufnr, "syntax", "markdown")
  end
  
  -- Apply mappings based on buffer type
  if ft == constants.BUFFER_FILETYPE then
    local buffer = _G.bitbucket_buffers[bufnr]
    if buffer then
      M.apply_pr_mappings(bufnr, buffer.kind)
    end
  elseif ft == constants.REVIEW_FILETYPE then
    -- Review mappings are handled by the review module
  end
end

-- Apply PR/Issue buffer mappings
function M.apply_pr_mappings(bufnr, kind)
  if config.values.mappings_disable_default then
    return
  end
  
  local mappings = config.values.mappings
  local map_kind = kind == "pull_request" and "pull_request" or "issue"
  
  if not mappings[map_kind] then
    return
  end
  
  local buffer = _G.bitbucket_buffers[bufnr]
  
  -- Apply each mapping
  for action_name, map_def in pairs(mappings[map_kind]) do
    if map_def.lhs and map_def.desc then
      local mode = map_def.mode or "n"
      
      -- Define action handlers
      local action_handlers = {
        pr_options = function()
          M.show_buffer_actions(bufnr)
        end,
        checkout_pr = function()
          if buffer then
            require("bitbucket.commands").commands.pr.checkout(buffer.number)
          end
        end,
        merge_pr = function()
          if buffer then
            require("bitbucket.commands").commands.pr.merge(buffer.number)
          end
        end,
        close_pr = function()
          if buffer then
            require("bitbucket.commands").commands.pr.close(buffer.number)
          end
        end,
        reopen_pr = function()
          -- TODO: Implement reopen
          utils.info("Reopen not yet implemented")
        end,
        reload = function()
          if buffer then
            buffer:refresh()
          end
        end,
        open_in_browser = function()
          if buffer and buffer.node and buffer.node.links then
            local url = buffer.node.links.html and buffer.node.links.html.href
            if url then
              require("bitbucket.utils").open_in_browser(url)
            end
          end
        end,
        copy_url = function()
          if buffer and buffer.node and buffer.node.links then
            local url = buffer.node.links.html and buffer.node.links.html.href
            if url then
              require("bitbucket.utils").copy_to_clipboard(url)
            end
          end
        end,
        add_comment = function()
          require("bitbucket.commands").commands.comment.add()
        end,
        add_reply = function()
          -- Find comment at cursor
          local comment_id = M.get_comment_at_cursor(bufnr)
          if comment_id then
            require("bitbucket.commands").commands.comment.reply(comment_id)
          else
            utils.info("Place cursor on a comment to reply")
          end
        end,
        delete_comment = function()
          -- Find comment at cursor
          local comment_id = M.get_comment_at_cursor(bufnr)
          if comment_id then
            require("bitbucket.commands").commands.comment.delete(comment_id)
          else
            utils.info("Place cursor on a comment to delete")
          end
        end,
        edit_comment = function()
          -- Find comment at cursor
          local comment_id = M.get_comment_at_cursor(bufnr)
          if comment_id then
            require("bitbucket.commands").commands.comment.edit(comment_id)
          else
            utils.info("Place cursor on a comment to edit")
          end
        end,
        next_comment = function()
          M.jump_to_next_comment(bufnr, 1)
        end,
        prev_comment = function()
          M.jump_to_next_comment(bufnr, -1)
        end,
        review_start = function()
          if buffer then
            require("bitbucket.commands").commands.review.start(buffer.number)
          end
        end,
        review_resume = function()
          require("bitbucket.commands").commands.review.resume()
        end,
        resolve_thread = function()
          utils.info("Resolve thread - select a comment first")
        end,
        unresolve_thread = function()
          utils.info("Unresolve thread - select a comment first")
        end,
      }
      
      local handler = action_handlers[action_name]
      if handler then
        vim.keymap.set(mode, map_def.lhs, handler, {
          buffer = bufnr,
          silent = true,
          desc = map_def.desc,
        })
      end
    end
  end
end

-- Show buffer actions picker
function M.show_buffer_actions(bufnr)
  local buffer = _G.bitbucket_buffers[bufnr]
  if not buffer then
    return
  end
  
  local actions = {
    { name = "Reload", desc = "Refresh buffer" },
    { name = "Browser", desc = "Open in browser" },
    { name = "Copy URL", desc = "Copy URL to clipboard" },
    { name = "Add Comment", desc = "Add a comment" },
    { name = "Review", desc = "Start a review" },
  }
  
  if buffer.kind == "pull_request" then
    table.insert(actions, { name = "Checkout", desc = "Checkout PR branch" })
    table.insert(actions, { name = "Merge", desc = "Merge this PR" })
    table.insert(actions, { name = "Approve", desc = "Approve this PR" })
    table.insert(actions, { name = "Close", desc = "Decline/close this PR" })
  end
  
  require("bitbucket.picker").pick({
    items = actions,
    prompt = "Actions:",
    format = function(action)
      return action.name .. " - " .. action.desc
    end,
    action = function(action)
      -- Execute the action
      if action.name == "Reload" then
        buffer:refresh()
      elseif action.name == "Browser" then
        local url = buffer.node.links.html and buffer.node.links.html.href
        if url then
          require("bitbucket.utils").open_in_browser(url)
        end
      elseif action.name == "Copy URL" then
        local url = buffer.node.links.html and buffer.node.links.html.href
        if url then
          require("bitbucket.utils").copy_to_clipboard(url)
        end
      elseif action.name == "Add Comment" then
        require("bitbucket.commands").commands.comment.add()
      elseif action.name == "Review" then
        require("bitbucket.commands").commands.review.start(buffer.number)
      elseif action.name == "Checkout" then
        require("bitbucket.commands").commands.pr.checkout(buffer.number)
      elseif action.name == "Merge" then
        require("bitbucket.commands").commands.pr.merge(buffer.number)
      elseif action.name == "Approve" then
        require("bitbucket.commands").commands.pr.approve(buffer.number)
      elseif action.name == "Close" then
        require("bitbucket.commands").commands.pr.close(buffer.number)
      end
    end,
  })
end

-- Get comment ID at cursor position
function M.get_comment_at_cursor(bufnr)
  local buffer = _G.bitbucket_buffers[bufnr]
  if not buffer or not buffer.comments then
    return nil
  end
  
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1] - 1 -- 0-indexed
  
  -- Check if we're in a comment region
  for _, region in ipairs(buffer.metadata.comment_regions or {}) do
    if cursor_line >= region.start_line and cursor_line <= region.end_line then
      return region.comment_id
    end
  end
  
  return nil
end

-- Jump to next/previous comment
function M.jump_to_next_comment(bufnr, direction)
  local buffer = _G.bitbucket_buffers[bufnr]
  if not buffer or not buffer.comments or #buffer.comments == 0 then
    utils.info("No comments to navigate")
    return
  end
  
  local cursor_line = vim.api.nvim_win_get_cursor(0)[1] -- 1-indexed
  local target_line = nil
  
  -- Get all comment start lines
  local comment_lines = {}
  for _, region in ipairs(buffer.metadata.comment_regions or {}) do
    table.insert(comment_lines, region.start_line + 1) -- Convert to 1-indexed
  end
  
  table.sort(comment_lines)
  
  if direction > 0 then
    -- Find next comment
    for _, line in ipairs(comment_lines) do
      if line > cursor_line then
        target_line = line
        break
      end
    end
    -- Wrap around if needed
    if not target_line and #comment_lines > 0 then
      target_line = comment_lines[1]
    end
  else
    -- Find previous comment
    for i = #comment_lines, 1, -1 do
      if comment_lines[i] < cursor_line then
        target_line = comment_lines[i]
        break
      end
    end
    -- Wrap around if needed
    if not target_line and #comment_lines > 0 then
      target_line = comment_lines[#comment_lines]
    end
  end
  
  if target_line then
    vim.api.nvim_win_set_cursor(0, { target_line, 0 })
    -- Highlight briefly
    vim.api.nvim_buf_add_highlight(bufnr, -1, "IncSearch", target_line - 1, 0, -1)
    vim.defer_fn(function()
      vim.api.nvim_buf_clear_namespace(bufnr, -1, target_line - 1, target_line)
    end, 300)
  else
    utils.info("No more comments in this direction")
  end
end

-- Save buffer contents to Bitbucket
function M.save_buffer(bufnr)
  local buffer = _G.bitbucket_buffers[bufnr]
  if not buffer then
    utils.error("Not a bitbucket buffer")
    return
  end

  -- Update metadata before save to detect dirty regions
  if buffer.update_metadata then
    buffer:update_metadata()
  end

  -- Save through the buffer model
  if buffer.save then
    buffer:save(function(success, err)
      if success then
        vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
        utils.info("Saved successfully")
      else
        utils.error("Failed to save: " .. (err or "unknown error"))
      end
    end)
  end
end

-- Clean up buffer resources
function M.cleanup_buffer(bufnr)
  -- Clear statuscolumn tracking
  local ok, statuscolumn = pcall(require, "bitbucket.ui.statuscolumn")
  if ok then
    statuscolumn.remove(bufnr)
  end

  -- Remove from global tracking
  _G.bitbucket_buffers[bufnr] = nil

  -- Clear any signs or extmarks
  require("bitbucket.ui.signs").unplace_all(bufnr)
  require("bitbucket.ui.signs").clear_highlights(bufnr)
end

-- Handle buffer enter
function M.on_buffer_enter(bufnr)
  -- Could trigger refresh here if needed
  -- For now, just ensure buffer is tracked
  local buffer = _G.bitbucket_buffers[bufnr]
  if buffer and buffer.refresh then
    -- Optionally auto-refresh
    -- buffer:refresh()
  end
end

return M
