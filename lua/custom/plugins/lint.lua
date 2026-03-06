return {
  'mfussenegger/nvim-lint',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    local lint = require 'lint'

    lint.linters_by_ft = {
      -- Add linters by filetype as needed
      -- javascript = { 'eslint' },
      -- typescript = { 'eslint' },
      -- go = { 'golangcilint' },
      -- sql = { 'sqlfluff' },
      -- mysql = { 'sqlfluff' },
      -- markdown = { 'markdownlint' },
      -- dockerfile = { 'hadolint' },
      -- terraform = { 'terraform_validate' },
      -- tf = { 'terraform_validate' },
      -- yaml = { 'yamllint' },
    }

    -- Run linter on save
    vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
      callback = function() lint.try_lint() end,
    })
  end,
}
