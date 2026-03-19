-- After plugin initialization
-- This file is automatically loaded after the plugin is set up

-- Setup filetype detection for bitbucket:// URLs
vim.filetype.add({
  pattern = {
    ["bitbucket://.*"] = "bitbucket",
  },
})

-- Add syntax highlighting for bitbucket buffers
vim.api.nvim_create_autocmd("FileType", {
  pattern = "bitbucket",
  callback = function()
    -- Set up markdown syntax highlighting
    vim.bo.syntax = "markdown"
    
    -- Additional buffer-local settings can go here
  end,
})
