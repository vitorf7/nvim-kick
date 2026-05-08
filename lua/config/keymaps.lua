-- Keymaps configuration
-- vim: ts=2 sts=2 sw=2 et

-- Clear highlights on search when pressing <Esc>
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Alternative escape
vim.keymap.set('i', 'jj', '<Esc>', { desc = 'Escape with jj' })

-- Save shortcuts
vim.keymap.set('n', '<leader>w', '<cmd>w<CR>', { desc = '[W]rite/Save file' })
vim.keymap.set('n', '<C-s>', '<cmd>w!<CR>', { desc = 'Save buffer' })
vim.keymap.set('n', '<C-S-s>', '<cmd>wa!<CR>', { desc = 'Save all buffers' })

-- Close buffers (match nvim)
vim.keymap.set('n', '<C-q>', function() Snacks.bufdelete.delete() end, { desc = 'Close current buffer' })
vim.keymap.set('n', '<leader>q', function() Snacks.bufdelete.other() end, { desc = 'Close all buffers except current' })

-- Diagnostic navigation
vim.keymap.set('n', '[d', function() vim.diagnostic.jump { count = -1 } end, { desc = 'Prev diagnostic' })
vim.keymap.set('n', ']d', function() vim.diagnostic.jump { count = 1 } end, { desc = 'Next diagnostic' })
vim.keymap.set('n', '[e', function() vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR } end, { desc = 'Prev error' })
vim.keymap.set('n', ']e', function() vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR } end, { desc = 'Next error' })
vim.keymap.set('n', '[w', function() vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.WARN } end, { desc = 'Prev warning' })
vim.keymap.set('n', ']w', function() vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.WARN } end, { desc = 'Next warning' })

-- Quickfix navigation
vim.keymap.set('n', '[q', vim.cmd.cprev, { desc = 'Prev quickfix' })
vim.keymap.set('n', ']q', vim.cmd.cnext, { desc = 'Next quickfix' })

-- Visual mode improvements
vim.keymap.set('v', 'p', 'P', { desc = 'Paste without replacing register' })
vim.keymap.set('v', '<', '<gv', { desc = 'Indent left and stay' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent right and stay' })

-- Terminal navigation - move between windows from terminal mode
vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-w>h', { desc = 'Go to left window' })
vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-w>j', { desc = 'Go to lower window' })
vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-w>k', { desc = 'Go to upper window' })
vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Go to right window' })
vim.keymap.set('t', '<C-/>', '<C-\\><C-n><cmd>Snacks.terminal()<cr>', { desc = 'Hide terminal' })

-- Text movement - move lines up/down with J/K in visual mode
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })

-- LSP reference navigation
vim.keymap.set('n', ']]', function()
  local ok, words = pcall(require, 'snacks.words')
  if ok then words.jump(vim.v.count1) end
end, { desc = 'Next LSP reference' })
vim.keymap.set('n', '[[', function()
  local ok, words = pcall(require, 'snacks.words')
  if ok then words.jump(-vim.v.count1) end
end, { desc = 'Previous LSP reference' })

-- Code lens keymaps (set in LSP attach)
-- These will be available when LSP attaches
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach-keymaps', { clear = true }),
  callback = function(event)
    local map = function(keys, func, desc) vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc }) end

    -- Code lens
    map('<leader>lc', vim.lsp.codelens.run, '[C]ode [L]ens Run')
    map('<leader>lC', vim.lsp.codelens.refresh, '[C]ode [L]ens Refresh')

    -- Float diagnostic for current line
    map('gl', function() vim.diagnostic.open_float { scope = 'line' } end, '[G]et [L]ine diagnostic')
  end,
})

-- Exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Map jk to Escape in insert mode
vim.keymap.set('i', 'jk', '<Esc>', { desc = 'Escape with jk' })
