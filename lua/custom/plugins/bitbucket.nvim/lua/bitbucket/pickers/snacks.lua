local M = {}

-- snacks.nvim picker implementation
-- This is a stub that will be fully implemented when snacks integration is built

function M.pick(opts)
  -- Fallback to default picker for now
  require("bitbucket.pickers.default").pick(opts)
end

function M.pick_multi(opts)
  require("bitbucket.pickers.default").pick_multi(opts)
end

function M.list(opts)
  require("bitbucket.pickers.default").list(opts)
end

function M.search(opts)
  require("bitbucket.pickers.default").search(opts)
end

function M.fzf(opts)
  require("bitbucket.pickers.default").fzf(opts)
end

return M
