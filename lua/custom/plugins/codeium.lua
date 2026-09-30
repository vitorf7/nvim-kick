return {
  'Exafunction/codeium.vim',
  enabled = true,
  event = { 'BufEnter' },
  init = function()
    -- The codeium language server's graceful SIGTERM shutdown deadlocks
    -- (the manager waits on its --run_child worker and vice versa), and
    -- nvim's exit sequence waits for its jobs to die — so :qa hangs
    -- forever. SIGKILL the whole server tree on the way out instead.
    -- VimLeavePre catches the normal case; VimLeave also catches the
    -- server being (re)started mid-quit, which the plugin's own BufEnter
    -- autocmd can do while qa wipes buffers.
    local kill_server = function()
      local job = vim.g.codeium_server_job
      if type(job) ~= 'number' or job <= 0 then
        return
      end
      local ok, pid = pcall(vim.fn.jobpid, job)
      if not ok or type(pid) ~= 'number' or pid <= 0 then
        return
      end
      vim.fn.system {
        'sh',
        '-c',
        'pkill -9 -P "$1" 2>/dev/null; kill -9 "$1" 2>/dev/null',
        'codeium-force-kill',
        tostring(pid),
      }
    end
    vim.api.nvim_create_autocmd({ 'VimLeavePre', 'VimLeave' }, {
      group = vim.api.nvim_create_augroup('codeium-force-kill', { clear = true }),
      callback = kill_server,
    })
  end,
}
