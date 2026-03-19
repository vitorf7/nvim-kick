local M = {}

---@class BitbucketConfig
---@field platform "auto"|"cloud"|"datacenter"
---@field auth_method "auto"|"env"|"config"|"cli"
---@field api_timeout number
---@field base_url string|nil
---@field prefer_cli boolean
---@field cli_cmd string
---@field picker "telescope"|"fzf-lua"|"snacks"|"default"
---@field enable_reviews boolean
---@field enable_issues boolean
---@field enable_pipelines boolean
---@field use_local_fs boolean

---@type BitbucketConfig
M.defaults = {
  platform = "auto", -- "cloud", "datacenter", "auto"
  auth_method = "auto", -- "env", "config", "cli", "auto"
  api_timeout = 10000,
  base_url = nil, -- For Data Center: "https://bitbucket.company.com"
  prefer_cli = true,
  cli_cmd = "bb",
  picker = "telescope",
  enable_reviews = true,
  enable_issues = true,
  enable_pipelines = true,
  use_local_fs = true,

  -- UI configuration (octo.nvim parity)
  snippet_context_lines = 4,
  timeline_indent = 2,

  -- Icon configuration
  comment_icon = "▎",
  timeline_marker = " ",
  outdated_icon = " ",
  resolved_icon = " ",
  user_icon = " ",
  ghost_icon = "󰊠 ",
  right_bubble_delimiter = "",
  left_bubble_delimiter = "",
  use_timeline_icons = true,

  -- Legacy icons table (for backward compat)
  icons = {
    pull_request = "",
    issue = "",
    comment = "▎",
    resolved = " ",
    outdated = "",
    user = "",
    thread = "",
  },

  timeline_icons = {
    auto_squash = "",
    commit_push = "",
    comment_deleted = "",
    force_push = "",
    draft = "",
    ready = "",
    commit = "",
    deployed = "",
    issue_type = "",
    label = "",
    reference = "",
    project = "",
    connected = "",
    subissue = "",
    cross_reference = "",
    transferred = "",
    parent_issue = "",
    head_ref = "",
    pinned = "",
    milestone = "",
    renamed = "",
    automatic_base_change_succeeded = "",
    base_ref_changed = "",
    merged = { "", "BitbucketPurple" },
    closed = { "", "BitbucketRed" },
    reopened = { "", "BitbucketGreen" },
    assigned = "",
    review_requested = "",
    -- Bitbucket-specific activity events
    approved = { "", "BitbucketGreen" },
    unapproved = { "", "BitbucketRed" },
    changes_requested = { "", "BitbucketRed" },
    updated = "",
    pipeline = "",
  },

  -- UI toggles
  ui = {
    use_signcolumn = false,
    use_statuscolumn = true,
    use_foldtext = true,
  },

  -- File panel settings
  file_panel = {
    size = 10,
    use_icons = true,
  },

  -- Review settings
  reviews = {
    auto_show_threads = true,
    focus = "right",
  },

  -- Color overrides (octo.nvim aligned defaults)
  colors = {
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
  },

  mappings_disable_default = false,
  mappings = {
    pull_request = {
      pr_options = { lhs = "<CR>", desc = "show PR options" },
      checkout_pr = { lhs = "<localleader>po", desc = "checkout PR" },
      merge_pr = { lhs = "<localleader>pm", desc = "merge PR" },
      close_pr = { lhs = "<localleader>ic", desc = "close PR" },
      reopen_pr = { lhs = "<localleader>io", desc = "reopen PR" },
      list_commits = { lhs = "<localleader>pc", desc = "list PR commits" },
      list_changed_files = { lhs = "<localleader>pf", desc = "list PR changed files" },
      show_pr_diff = { lhs = "<localleader>pd", desc = "show PR diff" },
      reload = { lhs = "<C-r>", desc = "reload PR" },
      open_in_browser = { lhs = "<C-b>", desc = "open PR in browser" },
      copy_url = { lhs = "<C-y>", desc = "copy URL to system clipboard" },
      add_assignee = { lhs = "<localleader>aa", desc = "add assignee" },
      remove_assignee = { lhs = "<localleader>ad", desc = "remove assignee" },
      add_comment = { lhs = "<localleader>ca", desc = "add comment" },
      add_reply = { lhs = "<localleader>cr", desc = "add reply" },
      delete_comment = { lhs = "<localleader>cd", desc = "delete comment" },
      next_comment = { lhs = "]c", desc = "go to next comment" },
      prev_comment = { lhs = "[c", desc = "go to previous comment" },
      review_start = { lhs = "<localleader>vs", desc = "start a review for the current PR" },
      review_resume = { lhs = "<localleader>vr", desc = "resume a pending review for the current PR" },
      resolve_thread = { lhs = "<localleader>rt", desc = "resolve PR thread" },
      unresolve_thread = { lhs = "<localleader>rT", desc = "unresolve PR thread" },
    },
    review_diff = {
      submit_review = { lhs = "<localleader>vs", desc = "submit review" },
      discard_review = { lhs = "<localleader>vd", desc = "discard review" },
      add_review_comment = { lhs = "<localleader>ca", desc = "add a new review comment", mode = { "n", "x" } },
      focus_files = { lhs = "<localleader>e", desc = "move focus to changed file panel" },
      toggle_files = { lhs = "<localleader>b", desc = "hide/show changed files panel" },
      next_thread = { lhs = "]t", desc = "move to next thread" },
      prev_thread = { lhs = "[t", desc = "move to previous thread" },
      select_next_entry = { lhs = "]q", desc = "move to next changed file" },
      select_prev_entry = { lhs = "[q", desc = "move to previous changed file" },
      select_first_entry = { lhs = "[Q", desc = "move to first changed file" },
      select_last_entry = { lhs = "]Q", desc = "move to last changed file" },
      select_next_unviewed_entry = { lhs = "]u", desc = "move to next unviewed changed file" },
      select_prev_unviewed_entry = { lhs = "[u", desc = "move to previous unviewed changed file" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
      toggle_viewed = { lhs = "<localleader><space>", desc = "toggle viewer viewed state" },
      goto_file = { lhs = "gf", desc = "go to file" },
    },
    file_panel = {
      submit_review = { lhs = "<localleader>vs", desc = "submit review" },
      discard_review = { lhs = "<localleader>vd", desc = "discard review" },
      next_entry = { lhs = "j", desc = "move to next changed file" },
      prev_entry = { lhs = "k", desc = "move to previous changed file" },
      select_entry = { lhs = "<cr>", desc = "show selected changed file diffs" },
      refresh_files = { lhs = "R", desc = "refresh changed files panel" },
      focus_files = { lhs = "<localleader>e", desc = "move focus to changed file panel" },
      toggle_files = { lhs = "<localleader>b", desc = "hide/show changed files panel" },
      close_review_tab = { lhs = "<C-c>", desc = "close review tab" },
      toggle_viewed = { lhs = "<localleader><space>", desc = "toggle viewer viewed state" },
    },
  },
}

---@type BitbucketConfig
M.values = {}

function M.validate_config(user_config)
  local valid_platforms = { auto = true, cloud = true, datacenter = true }
  local valid_auth = { auto = true, env = true, config = true, cli = true }
  local valid_pickers = { telescope = true, ["fzf-lua"] = true, snacks = true, default = true }

  if user_config.platform and not valid_platforms[user_config.platform] then
    vim.notify("Invalid platform: " .. user_config.platform, vim.log.levels.ERROR)
    return false
  end

  if user_config.auth_method and not valid_auth[user_config.auth_method] then
    vim.notify("Invalid auth_method: " .. user_config.auth_method, vim.log.levels.ERROR)
    return false
  end

  if user_config.picker and not valid_pickers[user_config.picker] then
    vim.notify("Invalid picker: " .. user_config.picker, vim.log.levels.ERROR)
    return false
  end

  return true
end

function M.setup(user_config)
  user_config = user_config or {}

  if not M.validate_config(user_config) then
    return
  end

  M.values = vim.tbl_deep_extend("force", M.defaults, user_config)

  -- Setup highlights
  require("bitbucket.ui.colors").setup()
end

return M
