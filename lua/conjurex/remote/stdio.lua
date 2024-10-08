-- [nfnl] Compiled from fnl/conjurex/remote/stdio.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local a = autoload("nfnl.core")
local client = autoload("conjurex.client")
local log = autoload("conjurex.log")
local str = autoload("nfnl.string")
local uv = vim.loop
local version = "conjurex.remote.stdio"
local function parse_prompt(s, pat)
  if s:find(pat) then
    return true, s:gsub(pat, "")
  else
    return false, s
  end
end
local function parse_cmd(x)
  if a["table?"](x) then
    return {cmd = a.first(x), args = a.rest(x)}
  elseif a["string?"](x) then
    return parse_cmd(str.split(x, "%s"))
  else
    return nil
  end
end
local function extend_env(vars)
  local function _5_(_4_)
    local k = _4_[1]
    local v = _4_[2]
    return (k .. "=" .. v)
  end
  return a.map(_5_, a["kv-pairs"](a.merge(vim.fn.environ(), vars)))
end
local function start(opts)
  log.dbg(version, ": start: opts>", a["pr-str"](opts), "<")
  local stdin = uv.new_pipe(false)
  local stdout = uv.new_pipe(false)
  local stderr = uv.new_pipe(false)
  local repl = {queue = {}, current = nil}
  local function destroy()
    log.dbg(version, ": start: destroy")
    local function _6_()
      return stdout:read_stop()
    end
    pcall(_6_)
    local function _7_()
      return stderr:read_stop()
    end
    pcall(_7_)
    local function _8_()
      return stdout:close()
    end
    pcall(_8_)
    local function _9_()
      return stderr:close()
    end
    pcall(_9_)
    local function _10_()
      return stdin:close()
    end
    pcall(_10_)
    if repl.handle then
      local function _11_()
        return uv.process_kill(repl.handle, uv.constants.SIGINT)
      end
      pcall(_11_)
      local function _12_()
        return repl.handle:close()
      end
      pcall(_12_)
      log.dbg(version, ": destroy: sent SIGINT to handle>", a["pr-str"](repl.handle), "<")
    else
    end
    return nil
  end
  local function on_exit(code, signal)
    log.dbg(version, ": on-exit: code>", a["pr-str"](code), "<\nsignal>", a["pr-str"](signal), "<")
    destroy()
    return client.schedule(opts["on-exit"], code, signal)
  end
  local function next_in_queue()
    log.dbg(version, ": next-in-queue: repl.queue>", a["pr-str"](repl.queue), "<")
    local next_msg = a.first(repl.queue)
    if (next_msg and not repl.current) then
      table.remove(repl.queue, 1)
      a.assoc(repl, "current", next_msg)
      log.dbg(version, ": send>", a["pr-str"](next_msg.code), "<")
      return stdin:write(next_msg.code)
    else
      return nil
    end
  end
  local function on_message(source, err, chunk)
    log.dbg(version, ": receive from>", a["pr-str"](source), "<\nerr>", err, "<\nchunk>", a["pr-str"](chunk), "<")
    if err then
      opts["on-error"](err)
      return destroy()
    else
      if chunk then
        local done_3f, result = parse_prompt(chunk, opts["prompt-pattern"])
        local cb = a["get-in"](repl, {"current", "cb"}, opts["on-stray-output"])
        if cb then
          log.dbg(version, ": received from ", source, "\nerr>", err, "<\nchunk>", a["pr-str"](chunk), "<")
          log.dbg(version, ":   err>", err, "<")
          log.dbg(version, ":   chunk>", a["pr-str"](chunk), "<")
          local function _15_()
            return cb({[source] = result, ["done?"] = done_3f})
          end
          pcall(_15_)
        else
        end
        if done_3f then
          a.assoc(repl, "current", nil)
          return next_in_queue()
        else
          return nil
        end
      else
        return nil
      end
    end
  end
  local function on_stdout(err, chunk)
    return on_message("out", err, chunk)
  end
  local function on_stderr(err, chunk)
    if opts["delay-stderr-ms"] then
      local function _20_()
        return on_message("err", err, chunk)
      end
      return vim.defer_fn(_20_, opts["delay-stderr-ms"])
    else
      return on_message("err", err, chunk)
    end
  end
  local function send(code, cb, opts0)
    local _22_
    if a.get(opts0, "batch?") then
      local msgs = {}
      local function _24_(msg)
        table.insert(msgs, msg)
        if msg["done?"] then
          return cb(msgs)
        else
          return nil
        end
      end
      _22_ = _24_
    else
      _22_ = cb
    end
    table.insert(repl.queue, {code = code, cb = _22_})
    next_in_queue()
    return nil
  end
  local function send_signal(signal)
    uv.process_kill(repl.handle, signal)
    return nil
  end
  local _let_27_ = parse_cmd(opts.cmd)
  local cmd = _let_27_["cmd"]
  local args = _let_27_["args"]
  local handle, pid_or_err = uv.spawn(cmd, {stdio = {stdin, stdout, stderr}, args = args, env = extend_env(a["merge!"]({INPUTRC = "/dev/null", TERM = "dumb"}, opts.env))}, client["schedule-wrap"](on_exit))
  if handle then
    stdout:read_start(client["schedule-wrap"](on_stdout))
    stderr:read_start(client["schedule-wrap"](on_stderr))
    local function _28_()
      return opts["on-success"]()
    end
    client.schedule(_28_)
    return a["merge!"](repl, {handle = handle, pid = pid_or_err, send = send, opts = opts, ["send-signal"] = send_signal, destroy = destroy})
  else
    local function _29_()
      return opts["on-error"](pid_or_err)
    end
    client.schedule(_29_)
    return destroy()
  end
end
return {["parse-cmd"] = parse_cmd, start = start, version = version}
