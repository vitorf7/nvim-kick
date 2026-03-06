-- Options configuration
-- vim: ts=2 sts=2 sw=2 et

-- Filetype associations (from nvim)
vim.filetype.add {
  extension = {
    jinja = 'jinja',
    jinja2 = 'jinja',
    j2 = 'jinja',
  },
}

-- Set to true if you have a Nerd Font installed
vim.g.have_nerd_font = true

-- Disable unused providers (from nvim)
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

-- [[ Setting options ]]
-- Make line numbers default
vim.o.number = true
vim.o.relativenumber = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.o.signcolumn = 'auto'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- Whitespace display
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor
vim.o.scrolloff = 10

-- Confirm before quitting with unsaved changes
vim.o.confirm = true

-- Better floating window borders
vim.o.winborder = 'rounded'

-- Smooth scrolling (Neovim 0.10+)
vim.o.smoothscroll = true

-- Better split behavior (keep cursor position)
vim.o.splitkeep = 'screen'

-- UFO fold settings
vim.o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:,diff:/]]
vim.o.foldcolumn = '1'
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
vim.o.foldenable = true

-- Performance and UX settings (from nvim)
vim.o.autowrite = true
vim.o.conceallevel = 2
vim.o.laststatus = 3
vim.o.pumheight = 20
vim.o.shiftround = true
vim.opt.shortmess:append { W = true, I = true, c = true, C = true }
vim.o.sidescrolloff = 8
vim.o.smartindent = true
vim.o.undolevels = 10000
vim.o.virtualedit = 'block'
vim.o.wildmode = 'longest:full,full'
vim.o.winminwidth = 5
vim.o.wrap = false
vim.o.colorcolumn = '80,140'
vim.o.termguicolors = true

-- Transparency for catppuccin theme because of nvim-cmp and lazyvim setting default values.
vim.o.pumblend = 0
vim.o.winblend = 0

-- Session management (from nvim)
vim.opt.sessionoptions = { 'buffers', 'curdir', 'tabpages', 'winsize', 'help', 'globals', 'skiprtp', 'folds' }

-- Indentation settings (match nvim)
vim.o.expandtab = true
vim.o.shiftwidth = 2
vim.o.softtabstop = 2
vim.o.tabstop = 2

-- Defer clipboard to speed up startup (from nvim)
vim.api.nvim_create_autocmd('User', {
  pattern = 'VeryLazy',
  once = true,
  callback = function() vim.opt.clipboard = 'unnamedplus' end,
})
