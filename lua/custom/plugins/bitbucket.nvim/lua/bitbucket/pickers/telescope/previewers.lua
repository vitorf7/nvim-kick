-- Telescope previewers (octo.nvim parity)
-- Provides rich preview rendering for PRs, issues, commits, changed files, and pipelines.
local M = {}

local writers = require("bitbucket.ui.writers")

--- PR previewer: renders a compact PR summary with state, details, and body excerpt.
function M.pr()
  local ok, previewers = pcall(require, "telescope.previewers")
  if not ok then
    return nil
  end

  return previewers.new_buffer_previewer({
    title = "Pull Request",
    define_preview = function(self, entry, status)
      local pr = entry.value
      if not pr then
        return
      end
      writers.pr_preview(pr, self.state.bufnr)
      vim.api.nvim_set_option_value("syntax", "markdown", { buf = self.state.bufnr })
    end,
  })
end

--- Issue previewer: renders a compact issue summary.
function M.issue()
  local ok, previewers = pcall(require, "telescope.previewers")
  if not ok then
    return nil
  end

  return previewers.new_buffer_previewer({
    title = "Issue",
    define_preview = function(self, entry, status)
      local issue = entry.value
      if not issue then
        return
      end
      writers.issue_preview(issue, self.state.bufnr)
      vim.api.nvim_set_option_value("syntax", "markdown", { buf = self.state.bufnr })
    end,
  })
end

--- Commit previewer: renders commit hash, message, author, date + diff.
function M.commit()
  local ok, previewers = pcall(require, "telescope.previewers")
  if not ok then
    return nil
  end

  return previewers.new_buffer_previewer({
    title = "Commit",
    define_preview = function(self, entry, status)
      local commit = entry.value
      if not commit then
        return
      end

      local lines = {}

      -- Header
      local hash = commit.hash or commit.id or "?"
      table.insert(lines, "Commit: " .. hash:sub(1, 12))

      if commit.author then
        local author_name = commit.author.raw or commit.author.display_name or "Unknown"
        table.insert(lines, "Author: " .. author_name)
      end

      if commit.date or commit.created_on then
        table.insert(lines, "Date:   " .. (commit.date or commit.created_on))
      end

      table.insert(lines, "")
      table.insert(lines, commit.message or "(no message)")

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

      -- Highlight header
      vim.api.nvim_buf_add_highlight(self.state.bufnr, -1, "BitbucketIssueTitle", 0, 8, -1)
      if #lines >= 2 then
        vim.api.nvim_buf_add_highlight(self.state.bufnr, -1, "BitbucketDetailsLabel", 1, 0, 8)
      end
    end,
  })
end

--- Changed files previewer: renders a file's patch as diff.
function M.changed_files()
  local ok, previewers = pcall(require, "telescope.previewers")
  if not ok then
    return nil
  end

  return previewers.new_buffer_previewer({
    title = "Changed File",
    define_preview = function(self, entry, status)
      local file = entry.value
      if not file then
        return
      end

      local lines = {}

      -- File header
      table.insert(lines, "File: " .. (file.path or file.new and file.new.path or "?"))
      table.insert(lines, "Status: " .. (file.status or "modified"))
      if file.additions then
        table.insert(lines, string.format("Changes: +%d -%d", file.additions or 0, file.deletions or 0))
      end
      table.insert(lines, "")

      -- Hunks as diff
      if file.hunks then
        for _, hunk in ipairs(file.hunks) do
          for _, hunk_line in ipairs(hunk.lines or {}) do
            table.insert(lines, hunk_line)
          end
        end
      end

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      vim.api.nvim_set_option_value("filetype", "diff", { buf = self.state.bufnr })
    end,
  })
end

--- Pipeline previewer: renders pipeline build number, state, branch, duration, steps.
function M.pipeline()
  local ok, previewers = pcall(require, "telescope.previewers")
  if not ok then
    return nil
  end

  return previewers.new_buffer_previewer({
    title = "Pipeline",
    define_preview = function(self, entry, status)
      local pipeline = entry.value
      if not pipeline then
        return
      end

      local lines = {}

      -- Build number
      table.insert(lines, "Build #" .. (pipeline.build_number or "?"))

      -- State
      local state = pipeline.state
      if state then
        local state_name = state.name or "unknown"
        local result = state.result and state.result.name or ""
        if result ~= "" then
          table.insert(lines, "Status: " .. state_name .. " (" .. result .. ")")
        else
          table.insert(lines, "Status: " .. state_name)
        end
      end

      -- Target/branch
      local target = pipeline.target
      if target then
        if target.ref_name then
          table.insert(lines, "Branch: " .. target.ref_name)
        end
        if target.commit and target.commit.hash then
          table.insert(lines, "Commit: " .. target.commit.hash:sub(1, 12))
        end
      end

      -- Dates
      if pipeline.created_on then
        table.insert(lines, "Created: " .. pipeline.created_on)
      end
      if pipeline.completed_on then
        table.insert(lines, "Completed: " .. pipeline.completed_on)
      end

      -- Duration
      if pipeline.build_seconds_used then
        local mins = math.floor(pipeline.build_seconds_used / 60)
        local secs = pipeline.build_seconds_used % 60
        table.insert(lines, string.format("Duration: %dm %ds", mins, secs))
      end

      -- Trigger
      if pipeline.trigger and pipeline.trigger.name then
        table.insert(lines, "Trigger: " .. pipeline.trigger.name)
      end

      vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)

      -- Highlight build number
      vim.api.nvim_buf_add_highlight(self.state.bufnr, -1, "BitbucketIssueTitle", 0, 0, -1)
    end,
  })
end

return M
