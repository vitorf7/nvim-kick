-- Autocommands configuration
-- vim: ts=2 sts=2 sw=2 et

-- Highlight when yanking text
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- Run linter on save
vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
  callback = function()
    require('lint').try_lint()
  end,
})

-- Markdown/MDX settings (from nvim)
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufFilePre', 'BufRead' }, {
  pattern = { '*.mdx', '*.md' },
  callback = function()
    vim.cmd [[set filetype=markdown wrap linebreak nolist nospell]]
  end,
})

-- .conf files as shell scripts (from nvim)
vim.api.nvim_create_autocmd({ 'BufRead' }, {
  pattern = { '*.conf' },
  callback = function()
    vim.cmd [[set filetype=sh]]
  end,
})

-- Terraform comment configuration (from nvim)
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'hcl', 'terraform' },
  desc = 'terraform/hcl commentstring configuration',
  command = 'setlocal commentstring=#\\ %s',
})

-- Tmux config reload (from nvim)
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = { '*tmux.conf' },
  command = "execute 'silent !tmux source <afile> --silent'",
})

-- Aerospace config reload (from nvim)
vim.api.nvim_create_autocmd('BufWritePost', {
  pattern = { 'aerospace.toml' },
  command = '!aerospace reload-config',
})

-- Auto-organize TypeScript/JavaScript imports on save
vim.api.nvim_create_autocmd('BufWritePre', {
  pattern = { '*.ts', '*.tsx', '*.js', '*.jsx' },
  group = vim.api.nvim_create_augroup('typescript-imports', { clear = true }),
  callback = function()
    -- Only run if typescript-tools is loaded
    local ok, tstools = pcall(require, 'typescript-tools.api')
    if ok then
      tstools.organize_imports(false)
    end
  end,
})
