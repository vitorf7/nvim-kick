local M = {}
local config = require("bitbucket.config")
local api = require("bitbucket.api")
local utils = require("bitbucket.utils")
local picker = require("bitbucket.picker")
local auth = require("bitbucket.auth")

-- Store active PRs being reviewed
M.active_prs = {}

-- Command definitions
M.commands = {
  pr = {
    list = function(state)
      local workspace, repo = M.get_repo_context()
      if not workspace or not repo then
        return
      end
      
      api.pullrequests.list({
        workspace = workspace,
        repo = repo,
        state = state,
      }, function(success, data, err)
        if not success then
          utils.error("Failed to list PRs: " .. (err or "unknown error"))
          return
        end
        
        local prs = data.values or {}
        
        if #prs == 0 then
          utils.info("No pull requests found")
          return
        end
        
        picker.pick({
          items = prs,
          prompt = "Pull Requests:",
          format = function(pr)
            local state_icon = pr.state == "OPEN" and "●" or (pr.state == "MERGED" and "◌" or "○")
            return string.format("%s #%d %s (%s)", state_icon, pr.id, pr.title, pr.author.display_name)
          end,
          action = function(pr)
            M.open_pr(pr)
          end,
        })
      end)
    end,
    
    view = function(id, repo_context)
      local workspace, repo = M.get_repo_context()
      if repo_context then
        workspace, repo = M.parse_repo_context(repo_context)
      end
      
      if not id then
        utils.error("PR ID is required")
        return
      end
      
      api.pullrequests.get({
        workspace = workspace,
        repo = repo,
        id = tonumber(id),
      }, function(success, data, err)
        if not success then
          utils.error("Failed to get PR: " .. (err or "unknown error"))
          return
        end
        
        M.open_pr(data)
      end)
    end,
    
    checkout = function(id)
      local workspace, repo = M.get_repo_context()
      
      if not id then
        -- List PRs and let user pick
        M.commands.pr.list()
        return
      end
      
      -- Use bb CLI if available
      if api.is_using_cli() then
        local cli = require("bitbucket.api.cli")
        cli.execute({ "pr", "checkout", id }, function(success, _, err)
          if success then
            utils.info("Checked out PR #" .. id)
          else
            utils.error("Failed to checkout: " .. (err or "unknown error"))
          end
        end)
      else
        -- Get PR info to find branch
        api.pullrequests.get({
          workspace = workspace,
          repo = repo,
          id = tonumber(id),
        }, function(success, data, err)
          if not success then
            utils.error("Failed to get PR: " .. (err or "unknown error"))
            return
          end
          
          local branch_name = data.source.branch.name
          local success2, _, err2 = utils.run_sync("git", { "checkout", branch_name })
          if success2 then
            utils.info("Checked out branch: " .. branch_name)
          else
            utils.error("Failed to checkout: " .. (err2 or "unknown error"))
          end
        end)
      end
    end,
    
    create = function()
      -- Get current branch
      local current_branch = utils.get_current_branch()
      if not current_branch then
        utils.error("Not in a git repository")
        return
      end
      
      -- Get default branch
      local success, default_branch, _ = utils.run_sync("git", { "remote", "show", "origin", "-n" })
      if success and default_branch then
        default_branch = default_branch:match("HEAD branch: (%S+)") or "main"
      else
        default_branch = "main"
      end
      
      -- Prompt for title
      vim.ui.input({ prompt = "PR Title: " }, function(title)
        if not title or title == "" then
          return
        end
        
        -- Prompt for destination branch
        vim.ui.input({ prompt = "Destination branch [" .. default_branch .. "]: " }, function(dest_branch)
          dest_branch = dest_branch ~= "" and dest_branch or default_branch
          
          -- Prompt for description (optional)
          vim.ui.input({ prompt = "Description (optional, use \n for newlines): " }, function(description)
            if description then
              description = description:gsub("\\n", "\n")
            end
            
            local workspace, repo = M.get_repo_context()
            
            api.pullrequests.create({
              workspace = workspace,
              repo = repo,
              title = title,
              source_branch = current_branch,
              destination_branch = dest_branch,
              description = description,
              close_source_branch = true,
            }, function(success, data, err)
              if success then
                utils.info("Created PR #" .. data.id .. ": " .. data.title)
                -- Open the new PR
                M.open_pr(data)
              else
                utils.error("Failed to create PR: " .. (err or "unknown error"))
              end
            end)
          end)
        end)
      end)
    end,
    
    merge = function(id, strategy)
      local workspace, repo = M.get_repo_context()
      
      if not id then
        utils.error("PR ID is required")
        return
      end
      
      strategy = strategy or "merge"
      local strategies = { "merge", "squash", "fast_forward" }
      
      vim.ui.select(strategies, {
        prompt = "Select merge strategy for PR #" .. id .. ":",
      }, function(selected_strategy)
        if not selected_strategy then
          return
        end
        
        vim.ui.select({ "Yes", "No" }, {
          prompt = "Merge PR #" .. id .. " with " .. selected_strategy .. " strategy?",
        }, function(choice)
          if choice ~= "Yes" then
            return
          end
          
          utils.info("Merging PR #" .. id .. "...")
          
          api.pullrequests.merge({
            workspace = workspace,
            repo = repo,
            id = tonumber(id),
            merge_strategy = selected_strategy,
            close_source_branch = true,
          }, function(success, data, err)
            if success then
              utils.info("Successfully merged PR #" .. id)
              -- Refresh the buffer if it's open
              for bufnr, buffer in pairs(_G.bitbucket_buffers or {}) do
                if buffer.kind == "pull_request" and buffer.number == tonumber(id) then
                  buffer:refresh()
                  break
                end
              end
            else
              utils.error("Failed to merge: " .. (err or "unknown error"))
            end
          end)
        end)
      end)
    end,
    
    approve = function(id)
      local workspace, repo = M.get_repo_context()
      
      if not id then
        utils.error("PR ID is required")
        return
      end
      
      utils.info("Approving PR #" .. id .. "...")
      
      api.pullrequests.approve({
        workspace = workspace,
        repo = repo,
        id = tonumber(id),
      }, function(success, _, err)
        if success then
          utils.info("Approved PR #" .. id)
          -- Refresh buffer if open
          for bufnr, buffer in pairs(_G.bitbucket_buffers or {}) do
            if buffer.kind == "pull_request" and buffer.number == tonumber(id) then
              buffer:refresh()
              break
            end
          end
        else
          utils.error("Failed to approve: " .. (err or "unknown error"))
        end
      end)
    end,
    
    unapprove = function(id)
      local workspace, repo = M.get_repo_context()
      
      if not id then
        utils.error("PR ID is required")
        return
      end
      
      api.pullrequests.unapprove({
        workspace = workspace,
        repo = repo,
        id = tonumber(id),
      }, function(success, _, err)
        if success then
          utils.info("Unapproved PR #" .. id)
          for bufnr, buffer in pairs(_G.bitbucket_buffers or {}) do
            if buffer.kind == "pull_request" and buffer.number == tonumber(id) then
              buffer:refresh()
              break
            end
          end
        else
          utils.error("Failed to unapprove: " .. (err or "unknown error"))
        end
      end)
    end,
    
    close = function(id)
      local workspace, repo = M.get_repo_context()
      
      if not id then
        utils.error("PR ID is required")
        return
      end
      
      vim.ui.select({ "Yes", "No" }, {
        prompt = "Decline/close PR #" .. id .. "?",
      }, function(choice)
        if choice ~= "Yes" then
          return
        end
        
        api.pullrequests.decline({
          workspace = workspace,
          repo = repo,
          id = tonumber(id),
        }, function(success, _, err)
          if success then
            utils.info("Declined PR #" .. id)
            for bufnr, buffer in pairs(_G.bitbucket_buffers or {}) do
              if buffer.kind == "pull_request" and buffer.number == tonumber(id) then
                buffer:refresh()
                break
              end
            end
          else
            utils.error("Failed to decline: " .. (err or "unknown error"))
          end
        end)
      end)
    end,
    
    diff = function(id)
      local workspace, repo = M.get_repo_context()
      
      if not id then
        utils.error("PR ID is required")
        return
      end
      
      -- Get PR info first
      api.pullrequests.get({
        workspace = workspace,
        repo = repo,
        id = tonumber(id),
      }, function(success, pr, err)
        if not success then
          utils.error("Failed to get PR: " .. (err or "unknown error"))
          return
        end
        
        -- Then get the diff
        api.pullrequests.get_diff({
          workspace = workspace,
          repo = repo,
          id = tonumber(id),
        }, function(success2, diff_data, err2)
          if not success2 then
            utils.error("Failed to get diff: " .. (err2 or "unknown error"))
            return
          end
          
          -- Show diff in a new buffer
          M.show_diff_buffer(pr, diff_data)
        end)
      end)
    end,
    
    commits = function(id)
      local workspace, repo = M.get_repo_context()
      
      if not id then
        utils.error("PR ID is required")
        return
      end
      
      api.pullrequests.get_commits({
        workspace = workspace,
        repo = repo,
        id = tonumber(id),
      }, function(success, data, err)
        if not success then
          utils.error("Failed to get commits: " .. (err or "unknown error"))
          return
        end
        
        local commits = data.values or {}
        
        picker.pick({
          items = commits,
          prompt = "PR Commits:",
          format = function(commit)
            local msg = commit.message:gsub("\n.*", "") -- First line only
            return string.format("%s %s (%s)", commit.hash:sub(1, 7), msg, commit.author.raw or "unknown")
          end,
          action = function(commit)
            -- Show commit details or open in browser
            if commit.links and commit.links.html then
              utils.open_in_browser(commit.links.html.href)
            end
          end,
        })
      end)
    end,
  },
  
  issue = {
    list = function()
      local workspace, repo = M.get_repo_context()
      
      api.issues.list({
        workspace = workspace,
        repo = repo,
      }, function(success, data, err)
        if not success then
          utils.error("Failed to list issues: " .. (err or "unknown error"))
          return
        end
        
        local issues = data.values or {}
        
        if #issues == 0 then
          utils.info("No issues found")
          return
        end
        
        picker.pick({
          items = issues,
          prompt = "Issues:",
          format = function(issue)
            local state_icon = issue.state == "open" and "●" or "○"
            return string.format("%s #%d %s (%s)", state_icon, issue.id, issue.title, issue.reporter.display_name)
          end,
          action = function(issue)
            M.open_issue(issue)
          end,
        })
      end)
    end,
    
    view = function(id)
      local workspace, repo = M.get_repo_context()
      
      if not id then
        utils.error("Issue ID is required")
        return
      end
      
      api.issues.get({
        workspace = workspace,
        repo = repo,
        id = tonumber(id),
      }, function(success, data, err)
        if not success then
          utils.error("Failed to get issue: " .. (err or "unknown error"))
          return
        end
        
        M.open_issue(data)
      end)
    end,
    
    create = function()
      vim.ui.input({ prompt = "Issue Title: " }, function(title)
        if not title or title == "" then
          return
        end
        
        vim.ui.input({ prompt = "Description (optional): " }, function(description)
          local workspace, repo = M.get_repo_context()
          
          api.issues.create({
            workspace = workspace,
            repo = repo,
            title = title,
            content = description,
          }, function(success, data, err)
            if success then
              utils.info("Created issue #" .. data.id .. ": " .. data.title)
              M.open_issue(data)
            else
              utils.error("Failed to create issue: " .. (err or "unknown error"))
            end
          end)
        end)
      end)
    end,
    
    close = function(id)
      local workspace, repo = M.get_repo_context()
      
      if not id then
        utils.error("Issue ID is required")
        return
      end
      
      vim.ui.select({ "Yes", "No" }, {
        prompt = "Close issue #" .. id .. "?",
      }, function(choice)
        if choice ~= "Yes" then
          return
        end
        
        api.issues.update({
          workspace = workspace,
          repo = repo,
          id = tonumber(id),
          state = "closed",
        }, function(success, _, err)
          if success then
            utils.info("Closed issue #" .. id)
            for bufnr, buffer in pairs(_G.bitbucket_buffers or {}) do
              if buffer.kind == "issue" and buffer.number == tonumber(id) then
                buffer:refresh()
                break
              end
            end
          else
            utils.error("Failed to close issue: " .. (err or "unknown error"))
          end
        end)
      end)
    end,
  },
  
  auth = {
    login = function()
      auth.prompt_login()
    end,
    
    logout = function()
      -- Clear config file auth
      local config_path = vim.fn.expand("~/.config/bitbucket.nvim/config.json")
      vim.fn.delete(config_path)
      auth.auth_info = nil
      utils.info("Logged out successfully")
    end,
    
    status = function()
      if auth.is_authenticated() then
        utils.info("Authenticated as: " .. (auth.get_username() or "unknown"))
        utils.info("Platform: " .. (auth.platform or "unknown"))
        if api.is_using_cli() then
          utils.info("API mode: CLI (bb)")
        else
          utils.info("API mode: REST API")
        end
      else
        utils.warn("Not authenticated. Run :Bitbucket auth login")
      end
    end,
  },
  
  review = {
    start = function(id)
      local workspace, repo = M.get_repo_context()
      
      if not id then
        -- Try to get ID from current buffer
        local current_buf = vim.api.nvim_get_current_buf()
        local buffer = _G.bitbucket_buffers[current_buf]
        if buffer and buffer.kind == "pull_request" then
          id = buffer.number
          workspace = buffer.workspace
          repo = buffer.repo
        else
          -- List PRs and let user pick
          M.commands.pr.list()
          return
        end
      end
      
      -- Load the review module and start review
      local review = require("bitbucket.reviews")
      review.start({
        workspace = workspace,
        repo = repo,
        id = tonumber(id),
      }, function(success, err)
        if not success then
          utils.error("Failed to start review: " .. (err or "unknown error"))
        end
      end)
    end,
    
    submit = function()
      local review = require("bitbucket.reviews")
      review.submit(function(success, err)
        if not success then
          utils.error("Failed to submit review: " .. (err or "unknown error"))
        end
      end)
    end,
    
    resume = function()
      local review = require("bitbucket.reviews")
      review.resume(function(success, err)
        if not success then
          utils.error("Failed to resume review: " .. (err or "unknown error"))
        end
      end)
    end,
    
    discard = function()
      vim.ui.select({ "Yes", "No" }, {
        prompt = "Discard all pending review comments?",
      }, function(choice)
        if choice ~= "Yes" then
          return
        end
        
        local review = require("bitbucket.reviews")
        review.discard(function(success, err)
          if not success then
            utils.error("Failed to discard review: " .. (err or "unknown error"))
          end
        end)
      end)
    end,
  },
  
  comment = {
    add = function()
      local current_buf = vim.api.nvim_get_current_buf()
      local buffer = _G.bitbucket_buffers[current_buf]
      
      if not buffer then
        utils.error("Not in a Bitbucket buffer")
        return
      end
      
      if buffer.kind ~= "pull_request" then
        utils.error("Can only add comments on pull requests")
        return
      end
      
      -- Open a floating window for comment input
      M.open_comment_editor(buffer)
    end,
    
    reply = function(comment_id)
      if not comment_id then
        utils.error("Comment ID is required. Place cursor on a comment and run :Bitbucket comment reply <id>")
        return
      end
      
      local current_buf = vim.api.nvim_get_current_buf()
      local buffer = _G.bitbucket_buffers[current_buf]
      
      if not buffer then
        return
      end
      
      -- Find the comment
      local parent_comment = nil
      for _, comment in ipairs(buffer.comments or {}) do
        if comment.id == tonumber(comment_id) then
          parent_comment = comment
          break
        end
      end
      
      if not parent_comment then
        utils.error("Comment not found: " .. comment_id)
        return
      end
      
      -- Open reply editor
      M.open_reply_editor(buffer, parent_comment)
    end,
    
    edit = function(comment_id)
      if not comment_id then
        utils.error("Comment ID is required. Place cursor on a comment and run :Bitbucket comment edit <id>")
        return
      end
      
      local current_buf = vim.api.nvim_get_current_buf()
      local buffer = _G.bitbucket_buffers[current_buf]
      
      if not buffer then
        return
      end
      
      -- Find the comment
      local comment = nil
      for _, c in ipairs(buffer.comments or {}) do
        if c.id == tonumber(comment_id) then
          comment = c
          break
        end
      end
      
      if not comment then
        utils.error("Comment not found: " .. comment_id)
        return
      end
      
      -- Check if user owns this comment
      local auth = require("bitbucket.auth")
      if comment.user.uuid ~= auth.get_user_uuid() then
        utils.error("You can only edit your own comments")
        return
      end
      
      -- Open edit editor with existing content
      M.open_comment_editor(buffer, comment)
    end,
    
    delete = function(comment_id)
      if not comment_id then
        utils.error("Comment ID is required")
        return
      end
      
      local current_buf = vim.api.nvim_get_current_buf()
      local buffer = _G.bitbucket_buffers[current_buf]
      
      if not buffer then
        return
      end
      
      -- Find the comment
      local comment = nil
      for _, c in ipairs(buffer.comments or {}) do
        if c.id == tonumber(comment_id) then
          comment = c
          break
        end
      end
      
      if not comment then
        utils.error("Comment not found: " .. comment_id)
        return
      end
      
      -- Confirm deletion
      vim.ui.select({ "Yes", "No" }, {
        prompt = "Delete this comment?",
      }, function(choice)
        if choice ~= "Yes" then
          return
        end
        
        api.comments.delete({
          workspace = buffer.workspace,
          repo = buffer.repo,
          id = buffer.number,
          comment_id = tonumber(comment_id),
        }, function(success, _, err)
          if success then
            utils.info("Comment deleted")
            buffer:load_comments(function()
              buffer:render_pull_request()
            end)
          else
            utils.error("Failed to delete: " .. (err or "unknown error"))
          end
        end)
      end)
    end,
    
    resolve = function(comment_id)
      if not comment_id then
        utils.error("Comment ID is required")
        return
      end
      
      local current_buf = vim.api.nvim_get_current_buf()
      local buffer = _G.bitbucket_buffers[current_buf]
      
      if not buffer then
        return
      end
      
      api.comments.resolve({
        workspace = buffer.workspace,
        repo = buffer.repo,
        id = buffer.number,
        comment_id = tonumber(comment_id),
      }, function(success, _, err)
        if success then
          utils.info("Resolved comment thread")
          buffer:load_comments()
        else
          utils.error("Failed to resolve: " .. (err or "unknown error"))
        end
      end)
    end,
    
    unresolve = function(comment_id)
      if not comment_id then
        utils.error("Comment ID is required")
        return
      end
      
      local current_buf = vim.api.nvim_get_current_buf()
      local buffer = _G.bitbucket_buffers[current_buf]
      
      if not buffer then
        return
      end
      
      api.comments.unresolve({
        workspace = buffer.workspace,
        repo = buffer.repo,
        id = buffer.number,
        comment_id = tonumber(comment_id),
      }, function(success, _, err)
        if success then
          utils.info("Unresolved comment thread")
          buffer:load_comments()
        else
          utils.error("Failed to unresolve: " .. (err or "unknown error"))
        end
      end)
    end,
  },
  
  repo = {
    view = function(repo_context)
      local workspace, repo = M.get_repo_context()
      if repo_context then
        workspace, repo = M.parse_repo_context(repo_context)
      end
      
      if not workspace or not repo then
        utils.error("Cannot determine repository")
        return
      end
      
      -- Open repository in browser
      local url
      if auth.platform == "cloud" then
        url = string.format("https://bitbucket.org/%s/%s", workspace, repo)
      else
        url = string.format("%s/projects/%s/repos/%s", 
          config.values.base_url or "",
          workspace,
          repo
        )
      end
      
      utils.open_in_browser(url)
    end,
  },
  
  health = {
    check = function()
      utils.info("=== Bitbucket.nvim Health Check ===")
      
      -- Check Neovim version
      local nvim_version = vim.version()
      utils.info(string.format("Neovim: %d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch))
      if nvim_version.major < 0 or (nvim_version.major == 0 and nvim_version.minor < 10) then
        utils.warn("Neovim 0.10+ recommended")
      else
        utils.info("✓ Neovim version OK")
      end
      
      -- Check dependencies
      local deps = { "plenary" }
      for _, dep in ipairs(deps) do
        local ok, _ = pcall(require, dep)
        if ok then
          utils.info("✓ " .. dep .. " installed")
        else
          utils.error("✗ " .. dep .. " not found (required)")
        end
      end
      
      -- Check optional pickers
      local pickers = { "telescope", "fzf-lua", "snacks" }
      for _, picker in ipairs(pickers) do
        local ok, _ = pcall(require, picker)
        if ok then
          utils.info("✓ " .. picker .. " installed (optional)")
        end
      end
      
      -- Check CLI availability
      if utils.command_exists("bb") then
        utils.info("✓ bb CLI found")
      else
        utils.info("- bb CLI not found (optional, REST API will be used)")
      end
      
      -- Check authentication
      if auth.is_authenticated() then
        utils.info("✓ Authenticated as: " .. (auth.get_username() or "unknown"))
        utils.info("  Platform: " .. (auth.platform or "unknown"))
        if api.is_using_cli() then
          utils.info("  API mode: CLI (bb)")
        else
          utils.info("  API mode: REST API")
        end
      else
        utils.warn("✗ Not authenticated - run :Bitbucket auth login")
      end
      
      -- Check git repository
      if utils.is_git_repo() then
        utils.info("✓ Git repository detected")
        local remotes = utils.get_git_info()
        if remotes then
          for _, remote in ipairs(remotes) do
            if remote.url:match("bitbucket") then
              utils.info("  Bitbucket remote: " .. remote.name .. " -> " .. remote.url)
            end
          end
        end
      else
        utils.warn("✗ Not in a git repository")
      end
      
      -- Test API connectivity
      if auth.is_authenticated() then
        local workspace, repo = M.get_repo_context()
        if workspace and repo then
          utils.info("Testing API connectivity...")
          api.pullrequests.list({ 
            workspace = workspace,
            repo = repo,
            limit = 1 
          }, function(success, _, err)
            if success then
              utils.info("✓ API connectivity OK")
            else
              utils.error("✗ API test failed: " .. (err or "unknown"))
            end
          end)
        else
          utils.warn("- Skipping API test: Cannot determine workspace/repository")
          utils.info("  Run this command from a git repository with a Bitbucket remote")
        end
      end
    end,
  },
}

-- Setup commands
function M.setup()
  -- Create main :Bitbucket command
  vim.api.nvim_create_user_command("Bitbucket", function(opts)
    M.octo(unpack(opts.fargs))
  end, {
    nargs = "*",
    complete = M.complete,
    desc = "Bitbucket CLI for Neovim",
  })
end

-- Main command dispatcher
function M.octo(...)
  local args = { ... }
  
  if #args == 0 then
    -- Show picker with available commands
    M.show_command_picker()
    return
  end
  
  -- Check if first arg is a URL
  local url = args[1]
  local parsed = utils.parse_url(url)
  
  if parsed then
    -- Open PR or repo from URL
    if parsed.type == "pull_request" then
      M.commands.pr.view(parsed.pr_id, (parsed.workspace or parsed.project) .. "/" .. parsed.repo)
    else
      M.commands.repo.view((parsed.workspace or parsed.project) .. "/" .. parsed.repo)
    end
    return
  end
  
  -- Parse command
  local object = args[1]
  local action = args[2]
  local command_args = {}
  
  for i = 3, #args do
    table.insert(command_args, args[i])
  end
  
  -- Execute command
  if M.commands[object] and M.commands[object][action] then
    M.commands[object][action](unpack(command_args))
  else
    utils.error("Unknown command: " .. object .. " " .. (action or ""))
  end
end

-- Command completion
function M.complete(arglead, cmdline, cursorpos)
  local completions = {}
  
  -- Add top-level commands
  for cmd, _ in pairs(M.commands) do
    table.insert(completions, cmd)
  end
  
  -- Add subcommands
  local parts = vim.split(cmdline, " ")
  if #parts >= 2 then
    local main_cmd = parts[2]
    if M.commands[main_cmd] then
      completions = {}
      for subcmd, _ in pairs(M.commands[main_cmd]) do
        table.insert(completions, main_cmd .. " " .. subcmd)
      end
    end
  end
  
  -- Filter by arglead
  local filtered = {}
  for _, completion in ipairs(completions) do
    if completion:match("^" .. arglead) then
      table.insert(filtered, completion)
    end
  end
  
  return filtered
end

-- Show command picker
function M.show_command_picker()
  local commands = {
    { name = "pr list", desc = "List pull requests" },
    { name = "pr view", desc = "View a pull request" },
    { name = "pr checkout", desc = "Checkout a PR branch" },
    { name = "pr create", desc = "Create a new PR" },
    { name = "pr merge", desc = "Merge a PR" },
    { name = "pr approve", desc = "Approve a PR" },
    { name = "pr unapprove", desc = "Unapprove a PR" },
    { name = "pr close", desc = "Decline/close a PR" },
    { name = "pr diff", desc = "View PR diff" },
    { name = "pr commits", desc = "List PR commits" },
    { name = "issue list", desc = "List issues" },
    { name = "issue view", desc = "View an issue" },
    { name = "issue create", desc = "Create an issue" },
    { name = "issue close", desc = "Close an issue" },
    { name = "review start", desc = "Start a PR review" },
    { name = "review submit", desc = "Submit pending review" },
    { name = "review resume", desc = "Resume pending review" },
    { name = "comment add", desc = "Add a comment" },
    { name = "comment reply", desc = "Reply to comment at cursor" },
    { name = "comment edit", desc = "Edit comment at cursor" },
    { name = "comment delete", desc = "Delete comment at cursor" },
    { name = "comment resolve", desc = "Resolve thread" },
    { name = "auth login", desc = "Authenticate with Bitbucket" },
    { name = "auth logout", desc = "Log out" },
    { name = "auth status", desc = "Check authentication status" },
    { name = "repo view", desc = "Open repository in browser" },
    { name = "health check", desc = "Run health check" },
  }
  
  picker.pick({
    items = commands,
    prompt = "Bitbucket Commands:",
    format = function(cmd)
      return cmd.name .. " - " .. cmd.desc
    end,
    action = function(cmd)
      local parts = vim.split(cmd.name, " ")
      M.octo(unpack(parts))
    end,
  })
end

-- Helper: Get current repo context
function M.get_repo_context()
  local workspace = nil
  local repo = nil
  
  -- Try to parse from git remote
  local remotes = utils.get_git_info()
  if remotes then
    for _, remote in ipairs(remotes) do
      -- Parse HTTPS bitbucket.org URLs: https://bitbucket.org/workspace/repo.git
      local w, r = remote.url:match("bitbucket%.org/([^/]+)/([^/%.]+)")
      if w and r then
        workspace = w
        repo = r
        break
      end
      
      -- Parse SSH bitbucket.org URLs: git@bitbucket.org:workspace/repo.git
      w, r = remote.url:match("bitbucket%.org:([^/]+)/([^/]+)")
      if w and r then
        -- Remove .git suffix if present
        r = r:gsub("%.git$", "")
        workspace = w
        repo = r
        break
      end
      
      -- Parse Data Center HTTPS URLs: https://host/projects/PROJECT/repos/repo
      local p, dr = remote.url:match("/projects/([^/]+)/repos/([^/]+)")
      if p and dr then
        workspace = p
        repo = dr
        break
      end
      
      -- Parse Data Center SSH URLs: git@host:project/repo.git
      p, dr = remote.url:match(":([^/]+)/([^/]+)")
      if p and dr and not remote.url:match("bitbucket%.org") then
        -- Remove .git suffix if present
        dr = dr:gsub("%.git$", "")
        workspace = p
        repo = dr
        break
      end
    end
  end
  
  return workspace, repo
end

-- Helper: Parse repo context from string
function M.parse_repo_context(context)
  -- Format: "workspace/repo" or "project/repo"
  local parts = vim.split(context, "/")
  if #parts == 2 then
    return parts[1], parts[2]
  end
  return nil, nil
end

-- Helper: Open PR in buffer with full rendering
function M.open_pr(pr)
  local workspace, repo = M.get_repo_context()
  
  -- Parse workspace and repo from PR data if available
  if pr.links and pr.links.self then
    local url = pr.links.self.href
    local w, r = url:match("/repositories/([^/]+)/([^/]+)/")
    if w and r then
      workspace = w
      repo = r
    end
  end
  
  -- Create buffer
  local BitbucketBuffer = require("bitbucket.model.buffer")
  local buffer = BitbucketBuffer:new({
    kind = "pull_request",
    number = pr.id,
    workspace = workspace,
    repo = repo,
    node = pr,
  })
  
  -- Load comments
  buffer:load_comments(function()
    -- Render PR
    buffer:render_pull_request()
    
    -- Open the buffer in current window
    vim.api.nvim_set_current_buf(buffer.bufnr)
    
    -- Move cursor to top
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    
    utils.info("Opened PR #" .. pr.id .. ": " .. pr.title)
  end)
end

-- Helper: Open issue in buffer
function M.open_issue(issue)
  local workspace, repo = M.get_repo_context()
  
  -- Parse workspace and repo from issue data
  if issue.links and issue.links.self then
    local url = issue.links.self.href
    local w, r = url:match("/repositories/([^/]+)/([^/]+)/")
    if w and r then
      workspace = w
      repo = r
    end
  end
  
  -- Create buffer
  local BitbucketBuffer = require("bitbucket.model.buffer")
  local buffer = BitbucketBuffer:new({
    kind = "issue",
    number = issue.id,
    workspace = workspace,
    repo = repo,
    node = issue,
  })
  
  -- Render issue
  buffer:render_issue()
  
  -- Open the buffer
  vim.api.nvim_set_current_buf(buffer.bufnr)
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  
  utils.info("Opened issue #" .. issue.id .. ": " .. issue.title)
end

-- Helper: Show diff in a buffer
function M.show_diff_buffer(pr, diff_data)
  -- Create a new buffer for diff
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(bufnr, "filetype", "diff")
  vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
  vim.api.nvim_buf_set_option(bufnr, "swapfile", false)
  
  -- Set buffer name
  local bufname = string.format("bitbucket://%s/%s/pull/%d/diff", pr.workspace, pr.repo, pr.id)
  vim.api.nvim_buf_set_name(bufnr, bufname)
  
  -- Set content
  local lines = {}
  if type(diff_data) == "string" then
    -- Raw diff text
    for line in diff_data:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end
  elseif type(diff_data) == "table" and diff_data.raw then
    for line in diff_data.raw:gmatch("[^\r\n]+") do
      table.insert(lines, line)
    end
  end
  
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  
  -- Open in current window
  vim.api.nvim_set_current_buf(bufnr)
  
  utils.info("Showing diff for PR #" .. pr.id)
end

-- Helper: Open comment editor
-- @param buffer The PR buffer
-- @param existing_comment Optional comment to edit (nil for new comment)
function M.open_comment_editor(buffer, existing_comment)
  -- Create a floating window for comment input
  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(20, vim.o.lines - 4)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local comment_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(comment_bufnr, "filetype", "markdown")
  vim.api.nvim_buf_set_option(comment_bufnr, "buftype", "prompt")
  
  local title_text = existing_comment and " Edit Comment " or " Add Comment "
  
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = title_text,
    title_pos = "center",
  }
  
  local winnr = vim.api.nvim_open_win(comment_bufnr, true, win_opts)
  
  -- Add instructions and existing content if editing
  local lines = {
    "",
    existing_comment and " Edit your comment below. Press <C-s> to save, <C-c> to cancel."
                      or " Enter your comment below. Press <C-s> to submit, <C-c> to cancel.",
    "",
  }
  
  -- Add existing content if editing
  if existing_comment and existing_comment.content then
    local content = existing_comment.content
    if type(content) == "table" and content.raw then
      content = content.raw
    end
    for text_line in content:gmatch("[^\r\n]+") do
      table.insert(lines, text_line)
    end
  end
  
  -- Add empty line for new comments
  if not existing_comment then
    table.insert(lines, "")
  end
  
  vim.api.nvim_buf_set_lines(comment_bufnr, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(winnr, { #lines, 0 })
  
  -- Set up keymaps for the floating window
  local opts = { buffer = comment_bufnr }
  
  -- Submit/Save comment
  vim.keymap.set("n", "<C-s>", function()
    local content_lines = vim.api.nvim_buf_get_lines(comment_bufnr, 3, -1, false)
    local content = table.concat(content_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
    
    if content == "" then
      utils.warn("Cannot post empty comment")
      return
    end
    
    -- Close the floating window
    vim.api.nvim_win_close(winnr, true)
    
    if existing_comment then
      -- Update existing comment
      api.comments.update({
        workspace = buffer.workspace,
        repo = buffer.repo,
        id = buffer.number,
        comment_id = existing_comment.id,
        content = content,
      }, function(success, _, err)
        if success then
          utils.info("Comment updated successfully")
          -- Reload comments
          buffer:load_comments(function()
            buffer:render_pull_request()
          end)
        else
          utils.error("Failed to update comment: " .. (err or "unknown error"))
        end
      end)
    else
      -- Create new comment
      api.comments.create({
        workspace = buffer.workspace,
        repo = buffer.repo,
        id = buffer.number,
        content = content,
      }, function(success, _, err)
        if success then
          utils.info("Comment added successfully")
          -- Reload comments
          buffer:load_comments(function()
            buffer:render_pull_request()
          end)
        else
          utils.error("Failed to add comment: " .. (err or "unknown error"))
        end
      end)
    end
  end, opts)
  
  -- Cancel
  vim.keymap.set("n", "<C-c>", function()
    vim.api.nvim_win_close(winnr, true)
  end, opts)
  
  -- Also map Escape to cancel
  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(winnr, true)
  end, opts)
end

-- Helper: Open reply editor
-- @param buffer The PR buffer
-- @param parent_comment The comment to reply to
function M.open_reply_editor(buffer, parent_comment)
  -- Create a floating window for reply input
  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(20, vim.o.lines - 4)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2)
  
  local reply_bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(reply_bufnr, "filetype", "markdown")
  vim.api.nvim_buf_set_option(reply_bufnr, "buftype", "prompt")
  
  local win_opts = {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
    title = string.format(" Reply to %s ", parent_comment.user.display_name),
    title_pos = "center",
  }
  
  local winnr = vim.api.nvim_open_win(reply_bufnr, true, win_opts)
  
  -- Add instructions
  local lines = {
    "",
    string.format(" Replying to: %s", parent_comment.content.raw:gsub("\n", " "):sub(1, 50)),
    " Enter your reply below. Press <C-s> to submit, <C-c> to cancel.",
    "",
    "",
  }
  vim.api.nvim_buf_set_lines(reply_bufnr, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(winnr, { 5, 0 })
  
  -- Set up keymaps
  local opts = { buffer = reply_bufnr }
  
  -- Submit reply
  vim.keymap.set("n", "<C-s>", function()
    local content_lines = vim.api.nvim_buf_get_lines(reply_bufnr, 4, -1, false)
    local content = table.concat(content_lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
    
    if content == "" then
      utils.warn("Cannot post empty reply")
      return
    end
    
    -- Close the floating window
    vim.api.nvim_win_close(winnr, true)
    
    -- Bitbucket doesn't have a direct "reply" concept - we just create a regular comment
    -- that references the parent comment
    local full_content = string.format("Replying to @%s:\n\n%s", 
      parent_comment.user.display_name,
      content
    )
    
    api.comments.create({
      workspace = buffer.workspace,
      repo = buffer.repo,
      id = buffer.number,
      content = full_content,
      parent_id = parent_comment.id, -- Some platforms support threading
    }, function(success, _, err)
      if success then
        utils.info("Reply added successfully")
        -- Reload comments
        buffer:load_comments(function()
          buffer:render_pull_request()
        end)
      else
        utils.error("Failed to add reply: " .. (err or "unknown error"))
      end
    end)
  end, opts)
  
  -- Cancel
  vim.keymap.set("n", "<C-c>", function()
    vim.api.nvim_win_close(winnr, true)
  end, opts)
  
  vim.keymap.set("n", "<Esc>", function()
    vim.api.nvim_win_close(winnr, true)
  end, opts)
end

return M
