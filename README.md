# Neovim Configuration

A modular Neovim configuration based on kickstart.nvim with extensive customization.

## Features

- **Modular Plugin Structure**: Each plugin in its own file in `lua/custom/plugins/`
- **Snacks.nvim Picker**: Modern picker replacing Telescope with:
  - Dashboard
  - Image viewer
  - Indent guides
  - Notifier
  - Quickfile
  - Scope highlighting
  - Smooth scroll
  - Status column
  - Word highlighting
  - Zen mode
  - Input/Select UI
- **LSP Setup**: Complete LSP configuration with:
  - mason.nvim & mason-lspconfig
  - Support for: Go, Lua, TypeScript/JavaScript, HTML, CSS, SQL, Terraform, Protobuf
  - Inlay hints
  - Fidget for LSP loading indicators
- **Completion**: blink.cmp for fast completions
- **AI Completion**: Codeium for AI-powered suggestions
- **File Management**: mini.files for file browsing
- **Testing**: neotest with Go support
- **Debugging**: nvim-dap with Go debugger
- **Theme**: rose-pine colorscheme
- **UI Enhancements**:
  - noice.nvim for improved UI
  - trouble.nvim for diagnostics
  - dropbar for breadcrumbs
  - harpoon for quick file navigation
  - mini.nvim modules (ai, surround, statusline, pairs, comment)
  - gopher.nvim for Go development
  - sidekick.nvim for symbol outline

## Structure

```
.
├── init.lua                    # Main configuration entry point
├── lua/custom/plugins/         # Individual plugin configurations
│   ├── blink.lua              # blink.cmp - completion framework
│   ├── codeium.lua            # Codeium - AI completion
│   ├── conform.lua            # conform.nvim - formatting
│   ├── dap.lua                # nvim-dap - debugging
│   ├── dropbar.lua            # dropbar - breadcrumbs
│   ├── gitsigns.lua           # gitsigns - git integration
│   ├── gopher.lua             # gopher.nvim - Go tools
│   ├── guess-indent.lua       # guess-indent - auto detect indent
│   ├── harpoon.lua            # harpoon - quick file navigation
│   ├── init.lua               # Plugin directory init
│   ├── lazydev.lua            # lazydev.nvim - Lua dev
│   ├── lsp.lua                # LSP configuration
│   ├── mini.lua               # mini.nvim modules
│   ├── neotest.lua            # neotest - testing
│   ├── noice.lua              # noice.nvim - UI improvements
│   ├── rose-pine.lua          # Theme
│   ├── sidekick.lua           # sidekick - symbol outline
│   ├── snacks.lua             # snacks.nvim - core UI plugins
│   ├── todo-comments.lua      # todo-comments - highlight todos
│   ├── treesitter.lua         # treesitter - syntax highlighting
│   ├── trouble.lua            # trouble.nvim - diagnostics
│   └── which-key.lua          # which-key - keymap helper
```

## Installation

1. Backup your existing Neovim config (if any):
   ```bash
   mv ~/.config/nvim ~/.config/nvim.bak
   ```

2. Clone this repository to your Neovim config directory:
   ```bash
   git clone <repo-url> ~/.config/nvim
   ```

3. Start Neovim:
   ```bash
   nvim
   ```

   Lazy.nvim will automatically install all plugins on first launch.

## Key Mappings

### General
- `<Space>` - Leader key
- `<Esc>` - Clear search highlights
- `<C-h/j/k/l>` - Navigate between windows
- `<Esc><Esc>` - Exit terminal mode

### Picker (Snacks)
- `<leader>sh` - Search help
- `<leader>sk` - Search keymaps
- `<leader>sf` - Search files
- `<leader>sw` - Search current word
- `<leader>sg` - Search by grep
- `<leader>sd` - Search diagnostics
- `<leader>sb` - Search buffers
- `<leader><leader>` - Find existing buffers

### LSP
- `grn` - Rename
- `gra` - Code action
- `grr` - Find references
- `gri` - Go to implementation
- `grd` - Go to definition
- `grD` - Go to declaration
- `gO` - Document symbols
- `gW` - Workspace symbols
- `grt` - Type definition
- `<leader>th` - Toggle inlay hints

### Git
- `<leader>gb` - Git branches
- `<leader>gs` - Git status
- `<leader>gl` - LazyGit
- `]c` / `[c` - Next/previous git hunk
- `<leader>hs` - Stage hunk
- `<leader>hr` - Reset hunk
- `<leader>hp` - Preview hunk

### File Management
- `<leader>e` - Open file explorer (mini.files)
- `<C-/>` - Toggle terminal

### Testing
- `<leader>tt` - Run nearest test
- `<leader>tf` - Run test file
- `<leader>to` - Test output
- `<leader>ts` - Test summary

### Debugging
- `<F5>` - Start/Continue debugging
- `<F1>` - Step into
- `<F2>` - Step over
- `<F3>` - Step out
- `<leader>b` - Toggle breakpoint
- `<F7>` - Toggle DAP UI

### Other
- `<leader>a` - Add to Harpoon
- `<leader>A` - Harpoon menu
- `<C-h/t/n/s>` - Harpoon file 1/2/3/4
- `<leader>o` - Toggle Sidekick
- `<leader>cp` - Pick symbols (dropbar)
- `<leader>xt` - Todo comments (Trouble)
- `<leader>z` - Zen mode

## Adding Custom Plugins

To add a new plugin:

1. Create a new file in `lua/custom/plugins/` named after your plugin
2. Return a lazy.nvim plugin specification table
3. Restart Neovim - lazy.nvim will automatically load it

Example:
```lua
-- lua/custom/plugins/my-plugin.lua
return {
  'author/my-plugin.nvim',
  config = function()
    require('my-plugin').setup {}
  end,
}
```

## Customization

Edit the plugin files in `lua/custom/plugins/` to customize each plugin's behavior. The configuration uses lazy.nvim's plugin specification format.

## Troubleshooting

Run `:checkhealth` to diagnose issues with your Neovim configuration.

## Credits

- Based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
- Uses [lazy.nvim](https://github.com/folke/lazy.nvim) for plugin management
