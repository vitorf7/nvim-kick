local M = {}

-- Platform settings
M.PLATFORM_CLOUD = "cloud"
M.PLATFORM_DATACENTER = "datacenter"

-- API endpoints
M.CLOUD_API_BASE = "https://api.bitbucket.org/2.0"
M.DATACENTER_API_PATH = "/rest/api/latest"

-- URL patterns for parsing
M.URL_PATTERNS = {
  -- Bitbucket Cloud (HTTPS)
  cloud_pr = "https://bitbucket%.org/([^/]+)/([^/]+)/pull%-requests/(%d+)",
  cloud_repo = "https://bitbucket%.org/([^/]+)/([^/]+)",
  -- Bitbucket Cloud (SSH)
  cloud_repo_ssh = "git@bitbucket%.org:([^/]+)/([^/]+)%.git",
  -- Bitbucket Data Center (HTTPS)
  datacenter_pr = "https://([^/]+)/projects/([^/]+)/repos/([^/]+)/pull%-requests/(%d+)",
  datacenter_repo = "https://([^/]+)/projects/([^/]+)/repos/([^/]+)",
  -- Bitbucket Data Center (SSH)
  datacenter_repo_ssh = "git@[^:]+:([^/]+)/([^/]+)%.git",
}

-- Buffer/filetypes
M.BUFFER_FILETYPE = "bitbucket"
M.REVIEW_FILETYPE = "bitbucket-review"

-- Highlight namespaces (octo-style, granular)
M.HIGHLIGHT_NS = vim.api.nvim_create_namespace("bitbucket_highlight")
M.COMMENT_NS = vim.api.nvim_create_namespace("bitbucket_comment")
M.SIGN_NS = vim.api.nvim_create_namespace("bitbucket_signs")
M.VIRTUAL_TEXT_NS = vim.api.nvim_create_namespace("bitbucket_virtual_text")
M.REVIEW_NS = vim.api.nvim_create_namespace("bitbucket_review")
M.DETAILS_NS = vim.api.nvim_create_namespace("bitbucket_details")
M.REVIEW_LEFT_NS = vim.api.nvim_create_namespace("bitbucket_review_left")
M.REVIEW_RIGHT_NS = vim.api.nvim_create_namespace("bitbucket_review_right")

-- New namespaces for granular virtual text management (octo parity)
M.TITLE_VT_NS = vim.api.nvim_create_namespace("bitbucket_title_vt")
M.DIFFHUNK_VT_NS = vim.api.nvim_create_namespace("bitbucket_diffhunk_vt")
M.EVENT_VT_NS = vim.api.nvim_create_namespace("bitbucket_event_vt")
M.THREAD_HEADER_VT_NS = vim.api.nvim_create_namespace("bitbucket_thread_header_vt")
M.EMPTY_MSG_VT_NS = vim.api.nvim_create_namespace("bitbucket_empty_msg_vt")
M.SUMMARY_VT_NS = vim.api.nvim_create_namespace("bitbucket_summary_vt")
M.THREAD_NS = vim.api.nvim_create_namespace("bitbucket_thread")
M.FILE_PANEL_NS = vim.api.nvim_create_namespace("bitbucket_file_panel")
M.REVIEW_COMMENTS_NS = vim.api.nvim_create_namespace("bitbucket_review_comments")
M.PIPELINE_NS = vim.api.nvim_create_namespace("bitbucket_pipeline")

-- Highlight groups
M.HIGHLIGHT_GROUPS = {
  "BitbucketNormal",
  "BitbucketCursorLine",
  "BitbucketWinSeparator",
  "BitbucketSignColumn",
  "BitbucketStatusColumn",
  "BitbucketStatusLine",
  "BitbucketStatusLineNC",
  "BitbucketEndOfBuffer",
  "BitbucketUser",
  "BitbucketUserViewer",
  "BitbucketDate",
  "BitbucketLabel",
  "BitbucketLink",
  "BitbucketTitle",
  "BitbucketIssueTitle",
  "BitbucketIssueId",
  "BitbucketSectionHeader",
  "BitbucketDetailsLabel",
  "BitbucketDetailsValue",
  "BitbucketMissingDetails",
  "BitbucketStateOpen",
  "BitbucketStateClosed",
  "BitbucketStateMerged",
  "BitbucketStateDraft",
  "BitbucketComment",
  "BitbucketThread",
  "BitbucketDiffAdd",
  "BitbucketDiffDelete",
  "BitbucketDiffChange",
  "BitbucketFilePanelFileName",
  "BitbucketFilePanelPath",
  "BitbucketReviewComment",
  "BitbucketReviewThread",
  "BitbucketReviewAdd",
  "BitbucketReviewDelete",
  "BitbucketBubble",
  "BitbucketDirty",
  "BitbucketTimelineItemHeading",
  "BitbucketTimelineMarker",
}

-- PR states
M.PR_STATES = {
  OPEN = "OPEN",
  MERGED = "MERGED",
  DECLINED = "DECLINED",
  SUPERSEDED = "SUPERSEDED",
}

-- Comment states
M.COMMENT_STATES = {
  ACTIVE = "ACTIVE",
  RESOLVED = "RESOLVED",
  OUTDATED = "OUTDATED",
}

-- Review states
M.REVIEW_STATES = {
  APPROVED = "APPROVED",
  CHANGES_REQUESTED = "CHANGES_REQUESTED",
  COMMENTED = "COMMENTED",
  PENDING = "PENDING",
}

-- Issue states
M.ISSUE_STATES = {
  NEW = "new",
  OPEN = "open",
  RESOLVED = "resolved",
  CLOSED = "closed",
  DUPLICATE = "duplicate",
  INVALID = "invalid",
  WONTFIX = "wontfix",
}

-- Merge methods
M.MERGE_METHODS = {
  MERGE = "merge",
  SQUASH = "squash",
  FAST_FORWARD = "fast_forward",
}

-- Pipeline states (Cloud only)
M.PIPELINE_STATES = {
  PENDING = "PENDING",
  IN_PROGRESS = "IN_PROGRESS",
  COMPLETED = "COMPLETED",
  PAUSED = "PAUSED",
  HALTED = "HALTED",
}

M.PIPELINE_RESULT = {
  SUCCESSFUL = "SUCCESSFUL",
  FAILED = "FAILED",
  ERROR = "ERROR",
  STOPPED = "STOPPED",
  EXPIRED = "EXPIRED",
}

-- Error codes
M.ERRORS = {
  AUTH_REQUIRED = "AUTH_REQUIRED",
  AUTH_FAILED = "AUTH_FAILED",
  NOT_FOUND = "NOT_FOUND",
  FORBIDDEN = "FORBIDDEN",
  RATE_LIMITED = "RATE_LIMITED",
  NETWORK_ERROR = "NETWORK_ERROR",
  UNKNOWN = "UNKNOWN",
}

-- Pickers
M.PICKERS = {
  TELESCOPE = "telescope",
  FZF_LUA = "fzf-lua",
  SNACKS = "snacks",
  DEFAULT = "default",
}

return M
