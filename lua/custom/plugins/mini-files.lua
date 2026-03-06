return {
  'echasnovski/mini.files',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  opts = function(_, opts)
    -- I didn't like the default mappings, so I modified them
    -- Module mappings created only inside explorer.
    -- Use `''` (empty string) to not create one.
    opts.mappings = vim.tbl_deep_extend('force', opts.mappings or {}, {
      close = '<esc>',
      -- Use this if you want to open several files
      go_in = 'l',
      -- This opens the file, but quits out of mini.files (default L)
      go_in_plus = '<CR>',
      -- I swapped the following 2 (default go_out: h)
      -- go_out_plus: when you go out, it shows you only 1 item to the right
      -- go_out: shows you all the items to the right
      go_out = 'H',
      go_out_plus = 'h',
      -- Default <BS>
      reset = '<BS>',
      -- Default @
      reveal_cwd = '.',
      show_help = 'g?',
      -- Default =
      synchronize = 's',
      trim_left = '<',
      trim_right = '>',

      -- Below I created an autocmd with the "," keymap to open the highlighted
      -- directory in a tmux pane on the right
    })

    opts.windows = vim.tbl_deep_extend('force', opts.windows or {}, {
      preview = true,
      width_focus = 30,
      width_preview = 80,
    })

    opts.options = vim.tbl_deep_extend('force', opts.options or {}, {
      -- Whether to use for editing directories
      -- Disabled by default in LazyVim because neo-tree is used for that
      use_as_default_explorer = true,
      -- If set to false, files are moved to the trash directory
      -- To get this dir run :echo stdpath('data')
      -- ~/.local/share/neobean/mini.files/trash
      permanent_delete = false,
    })
    return opts
  end,

  keys = {
    {
      -- Open the directory of the file currently being edited
      -- If the file doesn't exist because you maybe switched to a new git branch
      -- open the current working directory
      '<leader>e',
      function() require('config.modules.mini-files-explorer').open() end,
      desc = 'Open mini.files (Directory of Current File or CWD if not exists)',
    },
    -- Open the current working directory
    {
      '<leader>E',
      function() require('mini.files').open(vim.uv.cwd(), true) end,
      desc = 'Open mini.files (cwd)',
    },
  },

  config = function(_, opts)
    -- Set up mini.files
    require('mini.files').setup(opts)

    -- Load Git integration
    require('config.modules.mini-files-git').setup()
  end,
}
