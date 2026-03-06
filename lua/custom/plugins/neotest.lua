return {
  'nvim-neotest/neotest',
  dependencies = {
    { 'nvim-neotest/nvim-nio' },
    { 'nvim-lua/plenary.nvim' },
    { 'antoinemadec/FixCursorHold.nvim' },
    { 'nvim-treesitter/nvim-treesitter' },
    { 'nvim-neotest/neotest-plenary' },
    {
      'fredrikaverpil/neotest-golang',
      version = '*',
      dependencies = {
        {
          'leoluz/nvim-dap-go',
          opts = {},
        },
      },
    },
    'nvim-neotest/neotest-jest',
    'marilari88/neotest-vitest',
  },
  opts = {
    log_level = vim.log.levels.DEBUG,
    adapters = {
      'neotest-plenary',
      -- Go adapter
      ['neotest-golang'] = {
        runner = 'gotestsum',
        go_test_args = { '-v', '-race', '-count=1', '-timeout=60s', '-coverprofile=' .. vim.fn.getcwd() .. '/coverage.out' },
        dap_go_enabled = true,
        testify_enabled = true,
        colorize_test_output = true,
        gotestsum_args = { '--format=standard-verbose' },
        warn_test_name_dupes = false,
      },
      -- Jest adapter (primary for JS/TS)
      ['neotest-jest'] = {
        jestCommand = 'npm test --',
        jestConfigFile = function()
          -- Look for jest config files
          local configs = {
            'jest.config.js',
            'jest.config.ts',
            'jest.config.mjs',
            'jest.config.cjs',
            'package.json',
          }
          for _, config in ipairs(configs) do
            if vim.fn.filereadable(vim.fn.getcwd() .. '/' .. config) == 1 then
              if config == 'package.json' then
                -- Check if package.json has jest config
                local content = vim.fn.readfile(vim.fn.getcwd() .. '/package.json')
                local json = vim.fn.json_decode(table.concat(content, '\n'))
                if json and json.jest then return 'package.json' end
              else
                return config
              end
            end
          end
          return nil
        end,
        env = { CI = true },
        cwd = function() return vim.fn.getcwd() end,
      },
      -- Vitest adapter (fallback)
      ['neotest-vitest'] = {
        vitestCommand = function()
          -- Detect package manager
          local cmd = 'npx vitest'
          if vim.fn.filereadable(vim.fn.getcwd() .. '/yarn.lock') == 1 then
            cmd = 'yarn vitest'
          elseif vim.fn.filereadable(vim.fn.getcwd() .. '/pnpm-lock.yaml') == 1 then
            cmd = 'pnpm vitest'
          end
          return cmd
        end,
        vitestConfigFile = function()
          -- Look for vitest config files
          local configs = {
            'vitest.config.ts',
            'vitest.config.js',
            'vitest.config.mjs',
            'vitest.config.mts',
          }
          for _, config in ipairs(configs) do
            if vim.fn.filereadable(vim.fn.getcwd() .. '/' .. config) == 1 then return config end
          end
          return nil
        end,
        cwd = function() return vim.fn.getcwd() end,
      },
    },
    status = { virtual_text = true },
    output = { open_on_run = true },
    quickfix = {
      open = function()
        if require('lazy.core.config').spec.plugins['trouble.nvim'] ~= nil then
          require('trouble').open { mode = 'quickfix', focus = false }
        else
          vim.cmd 'copen'
        end
      end,
    },
    -- Configure discovery to prefer Jest files over Vitest
    discovery = {
      enabled = true,
    },
    -- Running configuration
    running = {
      concurrent = true,
    },
  },
  config = function(_, opts)
    local neotest_ns = vim.api.nvim_create_namespace 'neotest'
    vim.diagnostic.config({
      virtual_text = {
        format = function(diagnostic)
          -- Replace newline and tab characters with space for more compact diagnostics
          local message = diagnostic.message:gsub('\n', ' '):gsub('\t', ' '):gsub('%s+', ' '):gsub('^%s+', '')
          return message
        end,
      },
    }, neotest_ns)

    if require('lazy.core.config').spec.plugins['trouble.nvim'] ~= nil then
      opts.consumers = opts.consumers or {}
      -- Refresh and auto close trouble after running tests
      ---@type neotest.Consumer
      opts.consumers.trouble = function(client)
        client.listeners.results = function(adapter_id, results, partial)
          if partial then return end
          local tree = assert(client:get_position(nil, { adapter = adapter_id }))

          local failed = 0
          for pos_id, result in pairs(results) do
            if result.status == 'failed' and tree:get_key(pos_id) then failed = failed + 1 end
          end
          vim.schedule(function()
            local trouble = require 'trouble'
            if trouble.is_open() then
              trouble.refresh()
              if failed == 0 then trouble.close() end
            end
          end)
          return {}
        end
      end
    end

    if opts.adapters then
      local adapters = {}
      for name, config in pairs(opts.adapters or {}) do
        if type(name) == 'number' then
          if type(config) == 'string' then config = require(config) end
          adapters[#adapters + 1] = config
        elseif config ~= false then
          local adapter = require(name)
          if type(config) == 'table' and not vim.tbl_isempty(config) then
            local meta = getmetatable(adapter)
            if adapter.setup then
              adapter.setup(config)
            elseif meta and meta.__call then
              adapter(config)
            else
              error('Adapter ' .. name .. ' does not support setup')
            end
          end
          adapters[#adapters + 1] = adapter
        end
      end
      opts.adapters = adapters
    end

    require('neotest').setup(opts)
  end,
  keys = {
    { '<leader>tt', function() require('neotest').run.run(vim.fn.expand '%') end, desc = 'Run File' },
    { '<leader>tr', function() require('neotest').run.run() end, desc = 'Run Nearest' },
    { '<leader>tf', function() require('neotest').run.run(vim.fn.expand '%') end, desc = 'Run [T]est [F]ile' },
    { '<leader>ts', function() require('neotest').summary.toggle() end, desc = 'Toggle Summary' },
    { '<leader>ta', function() require('neotest').run.attach() end, desc = '[T]est [A]ttach' },
    { '<leader>to', function() require('neotest').output.open { enter = true } end, desc = '[T]est [O]utput' },
    { '<leader>tS', function() require('neotest').run.stop() end, desc = 'Stop' },
    { '<leader>tw', function() require('neotest').watch.toggle() end, desc = '[T]est [W]atch mode' },
    { '<leader>tl', function() require('neotest').run.run_last() end, desc = 'Run [L]ast test' },
    { '<leader>td', function() require('neotest').run.run { strategy = 'dap' } end, desc = '[T]est [D]ebug' },
  },
}
