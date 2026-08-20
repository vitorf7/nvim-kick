return {
  'emrearmagan/atlas.nvim',
  cmd = { 'Atlas', 'AtlasDiff' },
  dependencies = {
    'nvim-tree/nvim-web-devicons', -- optional but recommended
    'MeanderingProgrammer/render-markdown.nvim', -- optional but recommended
    'esmuellert/codediff.nvim', -- optional (PullRequest diff)
    'sindrets/diffview.nvim', -- optional; or "dlyongemallo/diffview-plus.nvim"
  },
  -- See Configuration below
  opts = {
    ui = {
      picker = 'snacks',
    },
    pulls = {
      default_merge_method = 'squash',

      diff = {
        -- Any command that accepts explicit <base>...<head> Git revisions.
        open_cmd = 'CodeDiff', -- default; for example "DiffviewOpen" or "CodeDiff".
        show_review_panel = true, -- Set true to show the review panel when a diff opens.
        comment_display = 'virtual_lines', -- "virtual_lines" or compact "virtual_text" hints.
      },

      -- See Pulls Configuration below.
      providers = {
        ---@type AtlasGitHubConfig
        github = {
          cache_ttl = 300,

          ---@type AtlasGitHubViewConfig[]
          views = {
            {
              name = 'My PRs',
              key = '1',
              layout = 'plain',
              search = 'author:@me sort:updated-desc',
            },
            {
              name = 'Energy Team',
              key = '2',
              layout = 'compact',
              search = 'org:utilitywarehouse team:energy sort:updated-desc',
            },
          },

          bookmarks = {
            key = 'S', -- default
            label = 'Search', -- default
            items = {
              ['Drafts'] = 'is:pr is:draft author:@me',
              ['Recently merged'] = 'is:pr is:merged author:@me sort:updated-desc',
              ['Review requested'] = 'is:pr is:open review-requested:@me',
            },
          },
        },
      },
    },
  },
  keys = {
    -- using <leader>o which is the same as the Octo.nvim due to muscle memory
    { '<leader>o', '<cmd>Atlas<cr>', desc = 'Atlas' },
  },
}
