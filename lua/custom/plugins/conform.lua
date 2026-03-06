return {
  'stevearc/conform.nvim',
  event = { 'BufWritePre' },
  cmd = { 'ConformInfo' },
  keys = {
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
      local disable_filetypes = { c = true, cpp = true }
      if disable_filetypes[vim.bo[bufnr].filetype] then
        return nil
      else
        return {
          timeout_ms = 500,
          lsp_format = 'fallback',
        }
      end
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
}
