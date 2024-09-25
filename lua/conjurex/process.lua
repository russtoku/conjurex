-- [nfnl] Compiled from fnl/conjurex/process.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local a = autoload("nfnl.core")
local nvim = autoload("conjure.aniseed.nvim")
local str = autoload("nfnl.string")
local version = "conjurex"
local function executable_3f(cmd)
  return (1 == vim.fn.executable(a.first(str.split(cmd, "%s+"))))
end
local function running_3f(proc)
  if proc then
    return proc["running?"]
  else
    return false
  end
end
local state = {jobs = {}}
local function on_exit(job_id)
  local proc = state.jobs[job_id]
  if running_3f(proc) then
    a.assoc(proc, "running?", false)
    state.jobs[proc["job-id"]] = nil
    pcall(vim.api.nvim_buf_delete, proc.buf, {force = true})
    local on_exit0 = a["get-in"](proc, {"opts", "on-exit"})
    if on_exit0 then
      return on_exit0(proc)
    else
      return nil
    end
  else
    return nil
  end
end
nvim.ex.function_(str.join("\n", {"ConjureProcessOnExit(...)", "call luaeval(\"require('conjure.process')['on-exit'](unpack(_A))\", a:000)", "endfunction"}))
local function execute(cmd, opts)
  local win = vim.api.nvim_tabpage_get_win(0)
  local original_buf = vim.api.nvim_win_get_buf(win)
  local term_buf
  local _6_
  do
    local t_5_ = opts
    if (nil ~= t_5_) then
      t_5_ = t_5_["hidden?"]
    else
    end
    _6_ = t_5_
  end
  term_buf = vim.api.nvim_create_buf(not _6_, true)
  local proc = {cmd = cmd, buf = term_buf, ["running?"] = true, opts = opts}
  local job_id
  do
    vim.api.nvim_win_set_buf(win, term_buf)
    job_id = vim.fn.termopen(cmd, {on_exit = "ConjureProcessOnExit"})
  end
  if (job_id == 0) then
    error("invalid arguments or job table full")
  elseif (job_id == -1) then
    error(("'" .. cmd .. "' is not executable"))
  else
  end
  vim.api.nvim_win_set_buf(win, original_buf)
  state.jobs[job_id] = proc
  return a.assoc(proc, "job-id", job_id)
end
local function stop(proc)
  if running_3f(proc) then
    vim.fn.jobstop(proc["job-id"])
    on_exit(proc["job-id"])
  else
  end
  return proc
end
return {["executable?"] = executable_3f, execute = execute, ["on-exit"] = on_exit, ["running?"] = running_3f, stop = stop, version = version}