return {
  'pmizio/typescript-tools.nvim',
  event = 'LspAttach',
  dependencies = { 'nvim-lua/plenary.nvim', 'neovim/nvim-lspconfig' },
  ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
  opts = {
    settings = {
      tsserver_file_preferences = {
        importModuleSpecifierPreference = 'auto',
        importModuleSpecifierEnding = 'auto',
        includePackageJsonAutoImports = 'auto',
      },
      tsserver_format_options = {
        allowIncompleteCompletions = false,
        allowRenameOfImportPath = true,
      },
      separate_diagnostic_server = true,
      publish_diagnostic_on = 'insert_leave',
      expose_as_code_action = { 'fix_all', 'add_missing_imports', 'remove_unused_imports', 'remove_unused' },
    },
  },
  keys = {
    {
      '<leader>lo',
      '<cmd>TSToolsOrganizeImports<cr>',
      desc = '[L]SP: [O]rganize Imports',
      ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
    },
    {
      '<leader>li',
      '<cmd>TSToolsAddMissingImports<cr>',
      desc = '[L]SP: Add Missing [I]mports',
      ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
    },
    {
      '<leader>lR',
      '<cmd>TSToolsRemoveUnusedImports<cr>',
      desc = '[L]SP: [R]emove Unused Imports',
      ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
    },
    { '<leader>lF', '<cmd>TSToolsFixAll<cr>', desc = '[L]SP: [F]ix All', ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' } },
    {
      '<leader>lV',
      '<cmd>TSToolsRemoveUnused<cr>',
      desc = '[L]SP: Remove Unused [V]ariables',
      ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
    },
    {
      '<leader>lG',
      '<cmd>TSToolsGoToSourceDefinition<cr>',
      desc = '[L]SP: [G]o to Source Definition',
      ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
    },
    {
      '<leader>lI',
      '<cmd>TSToolsRenameFile<cr>',
      desc = '[L]SP: [I]mport Rename File',
      ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
    },
  },
  config = function(_, opts) require('typescript-tools').setup(opts) end,
}
