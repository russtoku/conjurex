-- [nfnl] fnl/conjurex/client/elixir/stdio.fnl
local _local_1_ = require("conjure.nfnl.module")
local autoload = _local_1_["autoload"]
local define = _local_1_["define"]
local core = autoload("conjure.nfnl.core")
local client = autoload("conjure.client")
local config = autoload("conjure.config")
local log = autoload("conjure.log")
local mapping = autoload("conjure.mapping")
local stdio = autoload("conjure.remote.stdio")
local str = autoload("conjure.nfnl.string")
local M = define("conjurex.client.elixir.stdio")
config.merge({client = {elixir = {stdio = {command = "iex", mix_command = "iex -S mix", prompt_pattern = "iex%(%d+%)> "}}}})
if config["get-in"]({"mapping", "enable_defaults"}) then
  config.merge({client = {elixir = {stdio = {mapping = {start = "cs", stop = "cS", interrupt = "ei"}}}}})
else
end
local cfg = config["get-in-fn"]({"client", "elixir", "stdio"})
local state
local function _3_()
  return {repl = nil}
end
state = client["new-state"](_3_)
M["buf-suffix"] = ".ex"
M["comment-prefix"] = "# "
M["form-node?"] = function(node)
  log.dbg(("M.form-node?: node:type = " .. core["pr-str"](node:type())))
  log.dbg(("M.form-node?: node:parent = " .. core["pr-str"](node:parent())))
  local parent = node:parent()
  if ("call" == node:type()) then
    return true
  elseif ("binary_operator" == node:type()) then
    return true
  elseif (("list" == node:type()) and not ("binary_operator" == parent:type())) then
    return true
  elseif ("integer" == node:type()) then
    return true
  elseif ("char" == node:type()) then
    return true
  elseif ("sigil" == node:type()) then
    return true
  elseif ("float" == node:type()) then
    return true
  elseif ("string" == node:type()) then
    return true
  elseif ("tuple" == node:type()) then
    return true
  elseif ("identifier" == node:type()) then
    return true
  elseif ("unary_operator" == node:type()) then
    return true
  elseif ("map" == node:type()) then
    return true
  elseif ("nil" == node:type()) then
    return true
  elseif ("integer" == node:type()) then
    return true
  elseif ("charlist" == node:type()) then
    return true
  else
    return false
  end
end
local function with_repl_or_warn(f, opts)
  local repl = state("repl")
  if repl then
    return f(repl)
  else
    return log.append({(M["comment-prefix"] .. "No REPL running")})
  end
end
local function prep_code(s)
  return (s .. "\n")
end
local function display_result(msg)
  local function _6_(_241)
    return (M["comment-prefix"] .. _241)
  end
  return log.append(core.map(_6_, msg))
end
local function remove_prompts(msgs)
  local function _7_(_241)
    return string.gsub(_241, "%.+%(%d+%)> +", "")
  end
  local function _8_(_241)
    return core["nil?"](string.find(_241, "iex:%d+"))
  end
  local function _9_(_241)
    return not ("" == _241)
  end
  return core.map(_7_, core.filter(_8_, core.filter(_9_, str.split(msgs, "\n"))))
end
M.unbatch = function(msgs)
  log.dbg(("M.unbatch: msgs=" .. core["pr-str"](msgs)))
  local function _10_(_241)
    return str.join("\n", _241)
  end
  local function _11_(_241)
    return remove_prompts(_241)
  end
  local function _12_(_241)
    return (core.get(_241, "out") or core.get(_241, "err"))
  end
  return {out = str.join(core.map(_10_, core.map(_11_, core.map(_12_, msgs))))}
end
M["format-msg"] = function(msg)
  log.dbg(("M.format-msg: msg=" .. core["pr-str"](msg)))
  local function _13_(line)
    return line
  end
  local function _14_(_241)
    return not str["blank?"](_241)
  end
  return core.map(_13_, core.filter(_14_, str.split(core.get(msg, "out"), "\n")))
end
M["eval-str"] = function(opts)
  log.dbg(("M.eval-str: opts=" .. core["pr-str"](opts)))
  local function _15_(repl)
    local function _16_(msgs)
      local msgs0 = M["format-msg"](M.unbatch(msgs))
      log.dbg(("M.eval-str: in cb: msgs=" .. core["pr-str"](msgs0)))
      opts["on-result"](str.join("\n", msgs0))
      return log.append(msgs0)
    end
    return repl.send(prep_code(opts.code), _16_, {["batch?"] = true})
  end
  return with_repl_or_warn(_15_)
end
M["eval-file"] = function(opts)
  return M["eval-str"](core.assoc(opts, "code", core.slurp(opts["file-path"])))
end
local function display_repl_status(status)
  return log.append({(M["comment-prefix"] .. cfg({"command"}) .. " (" .. (status or "no status") .. ")")}, {["break?"] = true})
end
M.stop = function()
  local repl = state("repl")
  if repl then
    repl.destroy()
    display_repl_status("stopped")
    return core.assoc(state(), "repl", nil)
  else
    return nil
  end
end
M.start = function()
  log.dbg(("start: prompt_pattern=" .. cfg({"prompt_pattern"}) .. "cmd=" .. cfg({"command"})))
  if state("repl") then
    return log.append({(M["comment-prefix"] .. "Can't start, REPL is already running."), (M["comment-prefix"] .. "Stop the REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "stop"}))}, {["break?"] = true})
  else
    local function _18_()
      display_repl_status("started")
      local function _19_(repl)
        local function _20_(msgs)
          return display_result(M["format-msg"](M.unbatch(msgs)))
        end
        return repl.send(prep_code(":help"), _20_, {["batch?"] = true})
      end
      return with_repl_or_warn(_19_)
    end
    local function _21_(err)
      return display_repl_status(err)
    end
    local function _22_(code, signal)
      if (("number" == type(code)) and (code > 0)) then
        log.append({(M["comment-prefix"] .. "process exited with code " .. core["pr-str"](code))})
      else
      end
      if (("number" == type(signal)) and (signal > 0)) then
        log.append({(M["comment-prefix"] .. "process exited with signal " .. core["pr-str"](signal))})
      else
      end
      return M.stop()
    end
    local function _25_(msg)
      return log.append(M["format-msg"](msg))
    end
    return core.assoc(state(), "repl", stdio.start({["prompt-pattern"] = cfg({"prompt_pattern"}), cmd = cfg({"command"}), ["on-success"] = _18_, ["on-error"] = _21_, ["on-exit"] = _22_, ["on-stray-output"] = _25_}))
  end
end
M["on-exit"] = function()
  return M.stop()
end
M.interrupt = function()
  local function _27_(repl)
    log.append({(M["comment-prefix"] .. " Sending interrupt signal.")}, {["break?"] = true})
    return repl["send-signal"]("sigint")
  end
  return with_repl_or_warn(_27_)
end
M["on-load"] = function()
  return M.start()
end
M["on-filetype"] = function()
  local function _28_()
    return M.start()
  end
  mapping.buf("ElixirStart", cfg({"mapping", "start"}), _28_, {desc = "Start the REPL"})
  local function _29_()
    return M.stop()
  end
  mapping.buf("ElixirStop", cfg({"mapping", "stop"}), _29_, {desc = "Stop the REPL"})
  local function _30_()
    return M.interrupt()
  end
  return mapping.buf("ElixirInterrupt", cfg({"mapping", "interrupt"}), _30_, {desc = "Interrupt the REPL"})
end
return M
