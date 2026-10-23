return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
    {
      '<leader>Tf',
      function()
        -- If autoformat is currently disabled for this buffer,
        -- then enable it, otherwise disable it
        if vim.b.disable_autoformat then
          vim.cmd 'FormatEnable'
          vim.notify 'Enabled autoformat for current buffer'
        else
          vim.cmd 'FormatDisable!'
          vim.notify 'Disabled autoformat for current buffer'
        end
      end,
      desc = 'Toggle autoformat for current buffer',
    },
    {
      '<leader>TF',
      function()
        -- If autoformat is currently disabled globally,
        -- then enable it globally, otherwise disable it globally
        if vim.g.disable_autoformat then
          vim.cmd 'FormatEnable'
          vim.notify 'Enabled autoformat globally'
        else
          vim.cmd 'FormatDisable'
          vim.notify 'Disabled autoformat globally'
        end
      end,
      desc = 'Toggle autoformat globally',
    },
    {
      '<leader>f',
      function() require('conform').format { async = true, lsp_format = 'fallback' } end,
      mode = '',
      desc = '[F]ormat buffer',
    },
  },
  opts = {
    notify_on_error = false,

    format_on_save = function(bufnr)
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then return end
      local disable_filetypes = { c = false, cpp = false }
      return {
        timeout_ms = 500,
        lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
      }
    end,
    formatters = {
      -- Applies the `formatters:` block of the nearest .golangci.yaml (gci, gofmt, gofumpt, goimports)
      golangci_lint_fmt = {
        command = 'golangci-lint',
        args = { 'fmt', '--stdin' },
        stdin = true,
        -- plain vim.fs call: `opts` is evaluated before the lazy-loaded conform is on the rtp
        cwd = function(_, ctx) return vim.fs.root(ctx.dirname, { '.golangci.yaml', '.golangci.yml' }) end,
        require_cwd = true,
      },
    },
    formatters_by_ft = {
      lua = { 'stylua' },
      go = function(bufnr)
        local ctx = require('conform.runner').build_context(bufnr, 'golangci_lint_fmt')

        -- Repos with a golangci config (e.g. go-mono) get formatted by golangci-lint itself,
        -- so gci sections, gofumpt and the gofmt rewrite rules always match what CI lints.
        local hasGolangciConfig = vim.fs.find({ '.golangci.yaml', '.golangci.yml' }, { path = ctx.dirname, upward = true })[1] ~= nil

        local configArgs
        if hasGolangciConfig then
          configArgs = { 'golangci_lint_fmt' }
        else
          configArgs = { 'goimports', 'gofumpt' }
          if string.find(ctx.dirname, '(telecom%-fixed%-line)') == nil then table.insert(configArgs, 'gci') end
        end

        local goMonoPathSeach1 = '(go%-mono)/(teams)/(contact%-channels)'
        local goMonoPathSeach2 = '(go%-mono)/(teams)/(help%-and%-support)'

        if string.find(ctx.dirname, goMonoPathSeach1) or string.find(ctx.dirname, goMonoPathSeach2) then table.insert(configArgs, 'golines') end

        return configArgs
      end,
      graphql = { 'prettierd' },
      javascript = { 'prettierd' },
      typescript = { 'prettierd' },
      javascriptreact = { 'prettierd' },
      typescriptreact = { 'prettierd' },
      css = { 'prettier' },
      html = { 'prettier' },
      json = { 'prettier' },
      yaml = { 'prettier' },
      markdown = { 'prettier' },
      sh = { 'shfmt' },
      terraform = { 'terraform_fmt' },
      tf = { 'terraform_fmt' },
      ['terraform-vars'] = { 'terraform_fmt' },
      proto = { 'buf' },
      toml = { 'taplo' },
      mysql = { 'sql_formatter' },
      sql = { 'sql_formatter' },
    },
  },
  config = function(_, opts)
    require('conform').setup(opts)

    vim.api.nvim_create_user_command('FormatDisable', function(args)
      if args.bang then
        -- :FormatDisable! disables autoformat for this buffer only
        vim.b.disable_autoformat = true
      else
        -- :FormatDisable disables autoformat globally
        vim.g.disable_autoformat = true
      end
    end, {
      desc = 'Disable autoformat-on-save',
      bang = true, -- allows the ! variant
    })

    vim.api.nvim_create_user_command('FormatEnable', function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, {
      desc = 'Re-enable autoformat-on-save',
    })
  end,
}
