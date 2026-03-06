local M = {}

M.open = function()
  local buf_name = vim.api.nvim_buf_get_name(0)
  local dir_name = vim.fn.fnamemodify(buf_name, ':p:h')
  if vim.fn.filereadable(buf_name) == 1 then
    -- Pass the full file path to highlight the file
    require('mini.files').open(buf_name, true)
  elseif vim.fn.isdirectory(dir_name) == 1 then
    -- If the directory exists but the file doesn't, open the directory
    require('mini.files').open(dir_name, true)
  else
    -- If neither exists, fallback to the current working directory
    require('mini.files').open(vim.uv.cwd(), true)
  end
end

return M
