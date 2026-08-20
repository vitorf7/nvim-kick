return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  config = function(_, opts)
    -- Setup snacks.nvim with the provided options
    require('snacks').setup(opts)

    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Load package scripts module and setup keymaps
        local package_scripts = require 'custom.package-scripts'
        vim.keymap.set('n', '<leader>ps', package_scripts.show_scripts_picker, { desc = '[P]ackage [S]cripts' })
        vim.keymap.set('n', '<leader>pb', function()
          local pkg_json = package_scripts.find_package_json()
          if not pkg_json then
            vim.notify('No package.json found', vim.log.levels.WARN)
            return
          end
          package_scripts.show_scripts_picker()
        end, { desc = '[P]ackage Script [B]ackground' })
      end,
    })
  end,
  opts = {
    -- Styles for transparency
    styles = {
      picker = { wo = { winblend = 0 } },
      input = { wo = { winblend = 0 } },
      notification = { wo = { winblend = 0 } },
      terminal = { wo = { winblend = 0 } },
    },
    -- Picker - replaces Telescope
    picker = {
      enabled = true,
      ui_select = true,
    },
    -- Dashboard
    dashboard = {
      enabled = function() return vim.fn.argc(-1) == 0 end,
      preset = {
        header = [[
 _     _________________   _   _ _____ _____ _________________ ______ 
| |   |  _  | ___ \  _  \ | | | |_   _|_   _|  _  | ___ \  ___|___  / 
| |   | | | | |_/ / | | | | | | | | |   | | | | | | |_/ / |_     / /  
| |   | | | |    /| | | | | | | | | |   | | | | | |    /|  _|   / /   
| |___\ \_/ / |\ \| |/ /  \ \_/ /_| |_  | | \ \_/ / |\ \| |   ./ /    
\_____/\___/\_| \_|___/    \___/ \___/  \_/  \___/\_| \_\_|   \_/     
]],
        keys = {
          { icon = ' ', key = 'e', desc = 'Explore Directory', action = ':lua require("mini.files").open()' },
          { icon = ' ', key = 'f', desc = 'Find File', action = ":lua Snacks.dashboard.pick('files')" },
          { icon = ' ', key = 'n', desc = 'New File', action = ':ene | startinsert' },
          { icon = ' ', key = 'g', desc = 'Find Text', action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = ' ', key = 'r', desc = 'Recent Files', action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = ' ', key = 'c', desc = 'Config', action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = '󰒲 ', key = 'l', desc = 'Lazy', action = ':Lazy', enabled = package.loaded.lazy ~= nil },
          { icon = ' ', key = 'u', desc = 'Update Mason', action = ':Mason' },
          { icon = ' ', key = 'q', desc = 'Quit', action = ':qa' },
        },
      },
      formats = {
        header = { '%s', align = 'center' },
      },
      sections = {
        { section = 'header', indent = 30 },
        {
          { section = 'keys', gap = 1, padding = 1 },
          { icon = ' ', title = 'Recent Files', section = 'recent_files', indent = 2, padding = 2 },
          { section = 'startup' },
          padding = 1,
          indent = 2,
        },
        {
          {
            pane = 2,
            section = 'terminal',
            height = 9,
            cmd = 'echo ""',
          },
          {
            pane = 2,
            icon = ' ',
            desc = 'Browse Repo',
            padding = 1,
            key = 'b',
            action = function() Snacks.gitbrowse() end,
          },
          function()
            local in_git = Snacks.git.get_root() ~= nil
            local cmds = {
              {
                icon = ' ',
                title = 'Open PRs',
                cmd = 'gh pr list -L 3 --author "@me"',
                key = 'P',
                action = function() vim.fn.jobstart('gh pr list --web', { detach = true }) end,
                height = 7,
              },
              {
                icon = ' ',
                title = 'Git Status',
                -- cmd = 'git --no-pager diff --stat -B -M -C',
                cmd = 'git status --short && echo "---" && git diff --stat --cached 2>/dev/null || echo "No staged changes"',
                height = 10,
              },
            }
            return vim.tbl_map(
              function(cmd)
                return vim.tbl_extend('force', {
                  pane = 2,
                  section = 'terminal',
                  enabled = in_git,
                  padding = 1,
                  ttl = 5 * 60,
                  indent = 3,
                }, cmd)
              end,
              cmds
            )
          end,
        },
      },
    },
    -- Indent guides
    indent = {
      enabled = true,
      indent = {
        char = '│',
      },
      scope = {
        enabled = true,
        char = '│',
      },
    },
    -- Notifications
    notifier = {
      enabled = true,
      timeout = 3000,
    },
    -- Quick file navigation
    quickfile = { enabled = true },
    -- Scope - tree sitter scope highlighting
    scope = { enabled = false },
    -- Smooth scrolling
    scroll = {
      enabled = true,
    },
    -- Words - LSP reference highlighting
    words = {
      enabled = true,
      debounce = 200,
    },
    -- Zen mode
    zen = {
      enabled = true,
    },
    -- Input UI replacement
    input = { enabled = true },
    -- Select UI replacement
    select = { enabled = true },
    -- Big file handling
    bigfile = { enabled = true },
    -- Animations
    animate = {
      enabled = true,
      duration = 20, -- ms per step
      easing = 'linear',
      fps = 60,
    },
  },
  keys = {
    -- Picker keymaps
    { '<leader>sh', function() Snacks.picker.help() end, desc = '[S]earch [H]elp' },
    { '<leader>sk', function() Snacks.picker.keymaps() end, desc = '[S]earch [K]eymaps' },
    { '<leader>sf', function() Snacks.picker.files() end, desc = '[S]earch [F]iles' },
    { '<leader>ss', function() Snacks.picker.lsp_symbols() end, desc = 'LSP [S]earch [S]ymbols' },
    { '<leader>sw', function() Snacks.picker.grep_word() end, desc = '[S]earch current [W]ord', mode = { 'n', 'v' } },
    {
      '<leader>sg',
      function()
        Snacks.picker.grep {
          hidden = true,
          ignored = true,
          cwd = Snacks.git.get_root(vim.api.nvim_buf_get_name(0)) or Snacks.git.get_root(vim.fn.expand '%:p') or vim.uv.cwd(),
        }
      end,
      desc = '[S]earch by [G]rep',
    },
    { '<leader>sd', function() Snacks.picker.diagnostics() end, desc = '[S]earch [D]iagnostics' },
    { '<leader>sD', function() Snacks.picker.diagnostics_buffer() end, desc = '[S]earch Buffer [D]iagnostics' },
    { '<leader>sR', function() Snacks.picker.resume() end, desc = '[S]earch [R]esume' },
    { '<leader>s.', function() Snacks.picker.recent() end, desc = '[S]earch Recent Files' },
    { '<leader>sb', function() Snacks.picker.buffers { hidden = true, nofile = true } end, desc = '[S]earch [B]uffers' },
    { '<leader><leader>', function() Snacks.picker.buffers { hidden = true, nofile = true } end, desc = '[ ] Find existing buffers' },
    { '<leader>/', function() Snacks.picker.lines() end, desc = '[/] Fuzzily search in current buffer' },
    { '<leader>s/', function() Snacks.picker.grep_buffers { hidden = true, nofile = true } end, desc = '[S]earch [/] in Open Files' },
    { '<leader>sn', function() Snacks.picker.files { cwd = vim.fn.stdpath 'config' } end, desc = '[S]earch [N]eovim files' },
    -- Git
    { '<leader>gb', function() Snacks.picker.git_branches() end, desc = 'Git [B]ranches' },
    { '<leader>gs', function() Snacks.picker.git_status() end, desc = 'Git [S]tatus' },
    { '<leader>gl', function() Snacks.lazygit() end, desc = '[G]it [L]azygit' },
    { '<leader>fgd', function() Snacks.picker.git_diff() end, desc = 'Git [D]iff' },
    { '<leader>fgl', function() Snacks.picker.git_log() end, desc = 'Git [L]og' },
    { '<leader>fgF', function() Snacks.picker.git_log_file() end, desc = 'Git Log [F]ile' },
    { '<leader>fgL', function() Snacks.picker.git_log_line() end, desc = 'Git Log [L]ine' },
    -- Other
    { '<leader>.', function() Snacks.scratch() end, desc = 'Toggle Scratch Buffer' },
    { '<leader>n', function() Snacks.notifier.show_history() end, desc = 'Notification History' },
    { '<leader>a', function() Snacks.dashboard() end, desc = 'Open [A]lpha/Dashboard' },
    { '<c-/>', function() Snacks.terminal() end, desc = 'Toggle Terminal' },
    { '<c-_>', function() Snacks.terminal() end, desc = 'which_key_ignore' },
    { '<leader>z', function() Snacks.zen() end, desc = 'Toggle [Z]en Mode' },
    { '<leader>bd', function() Snacks.bufdelete.delete() end, desc = '[B]uffer [D]elete' },
    { '<leader>:', function() Snacks.picker.command_history() end, desc = 'Command History' },
    { '<leader>fg', function() Snacks.picker.git_files() end, desc = '[F]ind [G]it files' },
    { '<leader>gB', function() Snacks.gitbrowse() end, desc = 'Git [B]rowse' },
    -- Additional pickers
    { '<leader>su', function() Snacks.picker.undo() end, desc = '[S]earch [U]ndo tree' },
    { '<leader>sj', function() Snacks.picker.jumps() end, desc = '[S]earch [J]umps' },
    { '<leader>sm', function() Snacks.picker.marks() end, desc = '[S]earch [M]arks' },
    { '<leader>s"', function() Snacks.picker.registers() end, desc = '[S]earch [R]egisters' },
    { '<leader>sC', function() Snacks.picker.commands() end, desc = '[S]earch [C]ommands' },
    { '<leader>sH', function() Snacks.picker.highlights() end, desc = '[S]earch [H]ighlights' },
    { '<leader>sa', function() Snacks.picker.autocmds() end, desc = '[S]earch [A]utocmds' },
    { '<leader>sc', function() Snacks.picker.command_history() end, desc = '[S]earch [C]ommand History' },
    { '<leader>s;', function() Snacks.picker.search_history() end, desc = '[S]earch History' },
    { '<leader>si', function() Snacks.picker.icons() end, desc = '[S]earch [I]cons' },
    { '<leader>sl', function() Snacks.picker.loclist() end, desc = '[S]earch [L]ocation List' },
    { '<leader>sM', function() Snacks.picker.man() end, desc = '[S]earch [M]an Pages' },
    { '<leader>sq', function() Snacks.picker.qflist() end, desc = '[S]earch [Q]uickfix List' },
    { '<leader>sp', function() Snacks.picker.lazy() end, desc = '[S]earch [P]lugin Specs' },
    { '<leader>uC', function() Snacks.picker.colorschemes() end, desc = '[U]I [C]olorschemes' },
  },
  init = function(_, opts)
    vim.api.nvim_create_autocmd('User', {
      pattern = 'VeryLazy',
      callback = function()
        -- Setup some globals for debugging (lazy-loaded)
        _G.dd = function(...) Snacks.debug.inspect(...) end
        _G.bt = function() Snacks.debug.backtrace() end
        vim.print = _G.dd -- Override print to use snacks for `:=` command

        -- Create some toggle mappings
        Snacks.toggle.option('spell', { name = 'Spelling' }):map '<leader>us'
        Snacks.toggle.option('wrap', { name = 'Wrap' }):map '<leader>uw'
        Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):map '<leader>uL'
        Snacks.toggle.diagnostics():map '<leader>ud'
        Snacks.toggle.line_number():map '<leader>ul'
        Snacks.toggle.option('conceallevel', { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 }):map '<leader>uc'
        Snacks.toggle.treesitter():map '<leader>uT'
        Snacks.toggle.option('background', { off = 'light', on = 'dark', name = 'Dark Background' }):map '<leader>ub'
        Snacks.toggle.inlay_hints():map '<leader>uh'
        Snacks.toggle.indent():map '<leader>ug'
        Snacks.toggle.dim():map '<leader>uD'
        Snacks.toggle.zen():map '<leader>uz'
        Snacks.toggle.zoom():map '<leader>uZ'
      end,
    })
  end,
}
