return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'theHamsta/nvim-dap-virtual-text',
    -- Language specific debuggers
    'leoluz/nvim-dap-go',
    -- JavaScript/TypeScript debugging
    'mxsdev/nvim-dap-vscode-js',
  },
  keys = {
    -- All debug controls under <leader>d (no F-keys)
    { '<leader>dc', function() require('dap').continue() end, desc = '[D]ebug: [C]ontinue' },
    { '<leader>di', function() require('dap').step_into() end, desc = '[D]ebug: Step [I]nto' },
    { '<leader>do', function() require('dap').step_over() end, desc = '[D]ebug: Step [O]ver' },
    { '<leader>dO', function() require('dap').step_out() end, desc = '[D]ebug: Step [O]ut' },
    { '<leader>du', function() require('dapui').toggle() end, desc = '[D]ebug: Toggle [U]I' },
    -- Breakpoints
    { '<leader>db', function() require('dap').toggle_breakpoint() end, desc = '[D]ebug: Toggle [B]reakpoint' },
    { '<leader>dB', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = '[D]ebug: Set [B]reakpoint' },
    -- Session control
    { '<leader>dC', function() require('dap').run_to_cursor() end, desc = '[D]ebug: Run to [C]ursor' },
    { '<leader>dt', function() require('dap').terminate() end, desc = '[D]ebug: [T]erminate' },
    { '<leader>dR', function() require('dap').restart() end, desc = '[D]ebug: [R]estart' },
    { '<leader>dl', function() require('dap').run_last() end, desc = '[D]ebug: Run [L]ast' },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    for name, sign in pairs(require('util').icons.dap) do
      sign = type(sign) == 'table' and sign or { sign }
      vim.fn.sign_define('Dap' .. name, { text = sign[1], texthl = sign[2] or 'DiagnosticInfo', linehl = sign[3], numhl = sign[3] })
    end

    -- DAP UI setup
    dapui.setup {
      -- icons = { expanded = '', collapsed = '', current_frame = '' },
      -- controls = {
      --   icons = {
      --     pause = '',
      --     play = '',
      --     step_into = '',
      --     step_over = '',
      --     step_out = '',
      --     step_back = '',
      --     run_last = '',
      --     terminate = '',
      --     disconnect = '',
      --   },
      -- },
    }

    -- Virtual text
    require('nvim-dap-virtual-text').setup {}

    -- DAP listeners
    dap.listeners.after.event_initialized['dapui_config'] = function() dapui.open() end
    dap.listeners.before.event_terminated['dapui_config'] = function() dapui.close() end
    dap.listeners.before.event_exited['dapui_config'] = function() dapui.close() end

    -- Go debugger setup
    require('dap-go').setup {}

    -- JavaScript/TypeScript debugger setup (vscode-js-debug)
    require('dap-vscode-js').setup {
      -- Path to vscode-js-debug installation
      -- Mason installs it to: ~/.local/share/nvim/mason/packages/js-debug-adapter
      debugger_path = vim.fn.stdpath 'data' .. '/mason/packages/js-debug-adapter',
      -- Which adapters to configure
      adapters = { 'pwa-node', 'pwa-chrome', 'pwa-msedge', 'node-terminal', 'pwa-extensionHost' },
    }

    -- JavaScript/TypeScript debugging configurations
    for _, language in ipairs { 'typescript', 'javascript', 'typescriptreact', 'javascriptreact' } do
      dap.configurations[language] = {
        -- Debug single Node.js file
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch file',
          program = '${file}',
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          protocol = 'inspector',
          console = 'integratedTerminal',
          outFiles = { '${workspaceFolder}/dist/**/*.js' },
          runtimeExecutable = 'node',
        },
        -- Debug Node.js with npm script
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Launch via NPM',
          runtimeExecutable = function()
            -- Detect package manager
            if vim.fn.filereadable(vim.fn.getcwd() .. '/pnpm-lock.yaml') == 1 then
              return 'pnpm'
            elseif vim.fn.filereadable(vim.fn.getcwd() .. '/yarn.lock') == 1 then
              return 'yarn'
            else
              return 'npm'
            end
          end,
          runtimeArgs = { 'run', 'dev' }, -- Change to your dev script name
          cwd = '${workspaceFolder}',
          sourceMaps = true,
          protocol = 'inspector',
          console = 'integratedTerminal',
          outFiles = { '${workspaceFolder}/dist/**/*.js' },
        },
        -- Debug Jest tests
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Debug Jest Tests',
          runtimeExecutable = function()
            if vim.fn.filereadable(vim.fn.getcwd() .. '/pnpm-lock.yaml') == 1 then
              return 'pnpm'
            elseif vim.fn.filereadable(vim.fn.getcwd() .. '/yarn.lock') == 1 then
              return 'yarn'
            else
              return 'npm'
            end
          end,
          runtimeArgs = {
            'run',
            'test',
            '--',
            '--runInBand',
            '--no-coverage',
            '--testTimeout=0',
            '--testPathPattern',
            '${fileBasenameNoExtension}',
          },
          cwd = '${workspaceFolder}',
          console = 'integratedTerminal',
          internalConsoleOptions = 'neverOpen',
          sourceMaps = true,
        },
        -- Debug Vitest tests
        {
          type = 'pwa-node',
          request = 'launch',
          name = 'Debug Vitest Tests',
          runtimeExecutable = 'npx',
          runtimeArgs = {
            'vitest',
            'run',
            '--reporter=verbose',
            '${fileBasenameNoExtension}',
          },
          cwd = '${workspaceFolder}',
          console = 'integratedTerminal',
          internalConsoleOptions = 'neverOpen',
          sourceMaps = true,
        },
        -- Attach to Node.js process
        {
          type = 'pwa-node',
          request = 'attach',
          name = 'Attach to process',
          processId = require('dap.utils').pick_process,
          cwd = '${workspaceFolder}',
          sourceMaps = true,
        },
        -- Debug in Chrome
        {
          type = 'pwa-chrome',
          request = 'launch',
          name = 'Launch Chrome',
          url = 'http://localhost:3000', -- Change to your dev server port
          webRoot = '${workspaceFolder}',
          sourceMaps = true,
          sourceMapPathOverrides = {
            ['webpack:///src/*'] = '${webRoot}/src/*',
            ['webpack:///./*'] = '${webRoot}/*',
            ['webpack:///*'] = '*',
          },
        },
        -- Debug in Edge
        {
          type = 'pwa-msedge',
          request = 'launch',
          name = 'Launch Edge',
          url = 'http://localhost:3000', -- Change to your dev server port
          webRoot = '${workspaceFolder}',
          sourceMaps = true,
          sourceMapPathOverrides = {
            ['webpack:///src/*'] = '${webRoot}/src/*',
            ['webpack:///./*'] = '${webRoot}/*',
            ['webpack:///*'] = '*',
          },
        },
      }
    end
  end,
}
