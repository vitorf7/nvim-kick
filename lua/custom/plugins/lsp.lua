return {
  'neovim/nvim-lspconfig',
  dependencies = {
    { 'mason-org/mason.nvim', opts = {} },
    { 'mason-org/mason-lspconfig.nvim' },
    'WhoIsSethDaniel/mason-tool-installer.nvim',
    'saghen/blink.cmp',
    'folke/lazydev.nvim',
  },
  config = function()
    -- Diagnostic configuration
    vim.diagnostic.config {
      update_in_insert = false,
      severity_sort = true,
      float = { border = 'rounded', source = 'if_many' },
      underline = { severity = vim.diagnostic.severity.ERROR },
      virtual_text = true,
      virtual_lines = false,
      jump = { float = true },
    }

    -- LSP attach autocommand
    vim.api.nvim_create_autocmd('LspAttach', {
      group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)

        local map = function(keys, func, desc, mode)
          mode = mode or 'n'
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
        end

        map('gd', function() Snacks.picker.lsp_definitions() end, '[G]oto [D]efinition')

        map('gr', function() Snacks.picker.lsp_references() end, '[G]oto [R]eferences')

        map('gi', function() Snacks.picker.lsp_implementations() end, '[G]oto [I]mplementation')

        map('gl', vim.diagnostic.open_float, '[G]oto [L]ine diagnostic')

        map('<leader>lD', function() Snacks.picker.lsp_type_definitions() end, '[L]SP Type [D]efinition')

        map('<leader>ls', function() Snacks.picker.lsp_symbols() end, '[L]SP: Document [S]ymbols')

        map('<leader>ws', function() Snacks.picker.lsp_workspace_symbols() end, '[W]orkspace [S]ymbols')

        -- Rename
        map('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')

        map('<leader>ca', vim.lsp.buf.code_action, '[C]ode [A]ction')

        -- ESLint specific keymaps
        if client and client.name == 'eslint' then
          map('<leader>le', function() vim.cmd 'EslintFixAll' end, '[L]SP: [E]SLint Fix All')
          map(
            '<leader>lE',
            function()
              vim.lsp.buf.code_action {
                context = { only = { 'source.fixAll.eslint' } },
                apply = true,
              }
            end,
            '[L]SP: [E]SLint Fix Current'
          )
        end

        if client and client.server_capabilities.documentFormattingProvider then map('<leader>lf', vim.lsp.buf.format, '[L]SP: [F]ormat') end

        if client and client.server_capabilities.codeLensProvider then
          map('<leader>lc', vim.lsp.codelens.run, '[L]SP: Run [C]ode Lens')
          map('<leader>lC', vim.lsp.codelens.run, '[L]SP: Refresh & Display [C]ode Lens')
        end

        map('K', vim.lsp.buf.hover, 'Hover Documentation')

        -- WARN: This is not Goto Definition, this is Goto Declaration.
        --  For example, in C this would take you to the header
        map('gD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

        -- Document highlighting
        if client and client:supports_method('textDocument/documentHighlight', event.buf) then
          local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
          vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.document_highlight,
          })
          vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
            buffer = event.buf,
            group = highlight_augroup,
            callback = vim.lsp.buf.clear_references,
          })
          vim.api.nvim_create_autocmd('LspDetach', {
            group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
            callback = function(event2)
              vim.lsp.buf.clear_references()
              vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
            end,
          })
        end

        -- Inlay hints toggle
        -- if client and client:supports_method('textDocument/inlayHint', event.buf) then
        --   map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
        -- end

        -- Refresh the codelens for the current line
        --  See `:help vim.lsp.codelens`
        if client and client.server_capabilities.codeLensProvider then
          if vim.lsp.codelens.enable then
            vim.lsp.codelens.enable(true, { bufnr = event.buf })
          else
            vim.lsp.codelens.refresh { bufnr = event.buf }
          end
        end
      end,
    })

    -- Get LSP capabilities from blink.cmp
    local capabilities = require('blink.cmp').get_lsp_capabilities()

    local lspconfig = require 'lspconfig'
    -- Language servers configuration
    local servers = {
      -- Go
      gopls = {
        on_attach = require('util.lsp').on_attach(function(client, bufnr)
          if client.name == 'gopls' then
            if not client.server_capabilities.semanticTokensProvider then
              local semantic = client.config.capabilities.textDocument.semanticTokens
              client.server_capabilities.semanticTokensProvider = {
                full = true,
                legend = {
                  tokenTypes = semantic.tokenTypes,
                  tokenModifiers = semantic.tokenModifiers,
                },
                range = true,
              }
            end
          end
        end),
        -- capabilities = opts.capabilities,
        settings = {
          -- https://go.googlesource.com/vscode-go/+/HEAD/docs/settings.md#settings-for
          gopls = {
            experimentalPostfixCompletions = true,
            usePlaceholders = true,
            gofumpt = true,
            codelenses = {
              gc_details = true,
              generate = true,
              regenerate_cgo = true,
              run_govulncheck = true,
              test = true,
              tidy = true,
              upgrade_dependency = true,
              vendor = true,
              vulncheck = true,
            },
            hints = {
              assignVariableTypes = true,
              compositeLiteralFields = true,
              compositeLiteralTypes = true,
              constantValues = true,
              functionTypeParameters = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
            analyses = {
              any = true,
              fieldalignment = true,
              nilness = true,
              shadow = true,
              unusedparams = true,
              unusedwrite = true,
              useany = true,
            },
            expandWorkspaceToModule = true,
            completeUnimported = true,
            staticcheck = true,
            directoryFilters = { '-.git', '-.vscode', '-.idea', '-.vscode-test', '-node_modules' },
            semanticTokens = true,
          },
        },
        -- override root_path for issue: https://github.com/golang/go/issues/63536
        root_path = function(fname)
          local root_files = {
            'tools/go.mod', -- monorepo override so root_path is ./monorepo/go/** not ./monorepo/**
            'go.work',
            'go.mod',
            '.git',
            '.golangci.yaml',
            '.golangci.yml',
            'flake.nix',
            'flake.lock',
          }

          -- return first parent dir that homes a found root_file
          return lspconfig.util.root_pattern(unpack(root_files))(fname) or vim.fs.dirname(fname)
        end,
      },
      -- Lua
      lua_ls = {
        settings = {
          Lua = {
            hint = { enable = true },
            completion = { callSnippet = 'Replace' },
            diagnostics = {
              disable = { 'missing-fields' },
              globals = { 'vim' },
            },
            workspace = {
              checkThirdParty = false,
              library = {
                vim.env.VIMRUNTIME,
                vim.fn.stdpath 'config',
              },
            },
          },
        },
      },
      -- TypeScript/JavaScript
      ts_ls = {
        settings = {
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = 'all',
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
            -- Auto-import and completion preferences
            preferences = {
              importModuleSpecifier = 'auto',
              importModuleSpecifierEnding = 'auto',
              includePackageJsonAutoImports = 'auto',
              autoImportFileExcludePatterns = {
                'node_modules/*',
                '.git/*',
                '**/dist/**',
                '**/build/**',
              },
            },
            completions = {
              completeFunctionCalls = true,
            },
          },
          javascript = {
            inlayHints = {
              includeInlayParameterNameHints = 'all',
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
              includeInlayEnumMemberValueHints = true,
            },
            -- Auto-import and completion preferences
            preferences = {
              importModuleSpecifier = 'auto',
              importModuleSpecifierEnding = 'auto',
              includePackageJsonAutoImports = 'auto',
              autoImportFileExcludePatterns = {
                'node_modules/*',
                '.git/*',
                '**/dist/**',
                '**/build/**',
              },
            },
            completions = {
              completeFunctionCalls = true,
            },
          },
        },
      },
      -- ESLint for linting and code actions
      eslint = {
        settings = {
          workingDirectories = { mode = 'auto' },
          format = false, -- Use conform for formatting
        },
      },
      -- HTML
      html = {},
      -- CSS
      cssls = {},
      -- SQL
      sqlls = {},
      -- Terraform
      terraformls = {},
      -- JSON with schemastore
      jsonls = {
        settings = {
          json = {
            schemas = require('schemastore').json.schemas(),
            validate = { enable = true },
          },
        },
      },
      -- YAML with schemastore
      yamlls = {
        settings = {
          yaml = {
            schemas = require('schemastore').yaml.schemas(),
            validate = true,
          },
        },
      },
      -- Golangci-lint LSP for advanced Go linting
      golangci_lint_ls = {

        cmd = { 'golangci-lint-langserver' },
        filetypes = { 'go', 'gomod', 'gowork', 'gosum' },
        init_options = {
          command = { 'golangci-lint', 'run', '--output.json.path', 'stdout', '--show-stats=false', '--issues-exit-code=1', '--path-mode=abs' },
        },
      },
      graphql = {},
      dockerls = {},
      docker_compose_language_service = {
        filetypes = { 'docker-compose.yml', 'docker-compose.yaml' },
      },
      harper_ls = {},
    }

    -- Ensure installed tools
    local ensure_installed = vim.tbl_keys(servers or {})
    vim.list_extend(ensure_installed, {
      'stylua',
      'shfmt',
      'prettier',
      'buf',
      'markdownlint',
      'yamllint',
      'yamlfmt',
      -- Go tooling
      'delve',
      'goimports',
      'gofumpt',
      'golangci-lint',
      'golangci-lint-langserver',
      'golines',
      'gci',
      'gotests',
      'gomodifytags',
      'iferr',
      'impl',
      'gotestsum',

      -- JavaScript/TypeScript tooling
      'eslint-lsp',
      'js-debug-adapter',
      'typescript-language-server',
      'yaml-language-server',
      'json-lsp',
    })

    require('mason-tool-installer').setup { ensure_installed = ensure_installed }

    -- Setup mason-lspconfig to auto-enable servers
    require('mason-lspconfig').setup {
      automatic_enable = true,
    }

    -- Configure servers (mason-lspconfig will auto-enable them)
    for name, config in pairs(servers) do
      config.capabilities = vim.tbl_deep_extend('force', {}, capabilities, config.capabilities or {})
      vim.lsp.config(name, config)
    end
  end,
}
