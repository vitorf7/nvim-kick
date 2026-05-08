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
    formatters_by_ft = {
      lua = { 'stylua' },
      go = function(bufnr)
        local configArgs = { 'goimports', 'gofumpt' }
        local ctx = require('conform.runner').build_context(bufnr, configArgs)

        local telecomFixedLine = '(telecom%-fixed%-line)'

        local startIndexTelecom, _ = string.find(ctx.dirname, telecomFixedLine)

        if startIndexTelecom == nil then table.insert(configArgs, 'gci') end

        local goMonoPathSeach1 = '(go%-mono)/(teams)/(contact%-channels)'
        local goMonoPathSeach2 = '(go%-mono)/(teams)/(help%-and%-support)'

        local startIndex1, _ = string.find(ctx.dirname, goMonoPathSeach1)
        local startIndex2, _ = string.find(ctx.dirname, goMonoPathSeach2)

        -- Snacks.debug('startIndex1 startIndex2', startIndex1, startIndex2)
        local startIndex = startIndex1 or startIndex2
        -- Snacks.debug('startIndex', startIndex)
        -- Snacks.debug('ctx.dirname', ctx.dirname)

        if startIndex ~= nil then table.insert(configArgs, 'golines') end

        Snacks.debug('config', configArgs)
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
