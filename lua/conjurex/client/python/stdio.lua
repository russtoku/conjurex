-- [nfnl] Compiled from fnl/conjurex/client/python/stdio.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local a = autoload("nfnl.core")
local b64 = autoload("conjure.remote.transport.base64")
local client = autoload("conjurex.client")
local config = autoload("conjure.config")
local log = autoload("conjurex.log")
local mapping = autoload("conjure.mapping")
local stdio = autoload("conjurex.remote.stdio")
local str = autoload("nfnl.string")
local text = autoload("conjurex.text")
local version = "conjurex.client.python.stdio"
config.merge({client = {python = {stdio = {command = "python3 -iq", ["prompt-pattern"] = ">>> ", ["delay-stderr-ms"] = 10}}}})
if config["get-in"]({"mapping", "enable_defaults"}) then
  config.merge({client = {python = {stdio = {mapping = {start = "cs", stop = "cS", interrupt = "ei"}}}}})
else
end
local cfg = config["get-in-fn"]({"client", "python", "stdio"})
local state
local function _3_()
  return {repl = nil}
end
state = client["new-state"](_3_)
local buf_suffix = ".py"
local comment_prefix = "# "
local function form_node_3f(node)
  return (("expression_statement" == node:type()) or ("import_statement" == node:type()) or ("import_from_statement" == node:type()) or ("with_statement" == node:type()) or ("function_definition" == node:type()) or ("for_statement" == node:type()) or ("call" == node:type()))
end
local function with_repl_or_warn(f, opts)
  local repl = state("repl")
  if repl then
    return f(repl)
  else
    return log.append({(comment_prefix .. "No REPL running"), (comment_prefix .. "Start REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "start"}))})
  end
end
local function is_assignment_3f(node)
  local and_5_ = (node:child_count() == 1)
  if and_5_ then
    local child = node:child(0)
    and_5_ = (child:type() == "assignment")
  end
  return and_5_
end
local function is_expression_3f(node)
  return (("expression_statement" == node:type()) and not is_assignment_3f(node))
end
local function str_is_python_expr_3f(s)
  local parser = vim.treesitter.get_string_parser(s, "python")
  local result = parser:parse()
  local tree = a.get(result, 1)
  local root = tree:root()
  return ((1 == root:child_count()) and is_expression_3f(root:child(0)))
end
local function get_exec_str(s)
  return ("import base64\nexec(base64.b64decode('" .. b64.encode(s) .. "'))\n")
end
local function prep_code(s)
  local python_expr = str_is_python_expr_3f(s)
  if python_expr then
    return (s .. "\n")
  else
    return get_exec_str(s)
  end
end
local function is_dots_3f(s)
  return (string.sub(s, 1, 3) == "...")
end
local function format_msg(msg)
  local function _8_(_241)
    return not is_dots_3f(_241)
  end
  local function _9_(_241)
    return ("" ~= _241)
  end
  return a.filter(_8_, a.filter(_9_, text["split-lines"](msg)))
end
local function get_console_output_msgs(msgs)
  local function _10_(_241)
    return (comment_prefix .. "(out) " .. _241)
  end
  return a.map(_10_, a.butlast(msgs))
end
local function get_expression_result(msgs)
  local result = a.last(msgs)
  if (a["nil?"](result) or is_dots_3f(result)) then
    return nil
  else
    return result
  end
end
local function get_all_console_output(msgs)
  local function _12_(_241)
    return (comment_prefix .. "(out) " .. _241)
  end
  return a.map(_12_, msgs)
end
local function get_all_output_msgs(msgs)
  return str.join("\n", msgs)
end
local function unbatch(msgs)
  local function _13_(_241)
    return (a.get(_241, "out") or a.get(_241, "err"))
  end
  return str.join("", a.map(_13_, msgs))
end
local function log_repl_output(msgs)
  local msgs0 = format_msg(unbatch(msgs))
  local console_output_msgs = get_console_output_msgs(msgs0)
  local cmd_result = get_expression_result(msgs0)
  if not a["empty?"](console_output_msgs) then
    log.append(console_output_msgs)
  else
  end
  if cmd_result then
    return log.append({cmd_result})
  else
    return nil
  end
end
local function eval_str(opts)
  local function return_handler(msgs)
    log.append({"client.python.stdio: in return-handler; msgs>", a["pr-str"](msgs), "<"})
    local msgs0 = format_msg(unbatch(msgs))
    local cmd_result = get_all_output_msgs(msgs0)
    local console_result = get_all_console_output(msgs0)
    if cmd_result then
      log.append(console_result)
    else
    end
    if opts["on-result"] then
      return opts["on-result"](cmd_result)
    else
      return nil
    end
  end
  local function _18_(repl)
    return repl.send(prep_code(opts.code), return_handler, {["batch?"] = true})
  end
  return with_repl_or_warn(_18_)
end
local function eval_file(opts)
  return eval_str(a.assoc(opts, "code", a.slurp(opts["file-path"])))
end
local function get_help(code)
  return str.join("", {"help(", str.trim(code), ")"})
end
local function doc_str(opts)
  if str_is_python_expr_3f(opts.code) then
    return eval_str(a.assoc(opts, "code", get_help(opts.code)))
  else
    return nil
  end
end
local function display_repl_status(status)
  return log.append({(comment_prefix .. cfg({"command"}) .. " (" .. (status or "no status") .. ")")}, {["break?"] = true})
end
local function stop()
  log.append({(comment_prefix .. " " .. version .. ".stop called")})
  local repl = state("repl")
  if repl then
    repl.destroy()
    display_repl_status("stopped")
    return a.assoc(state(), "repl", nil)
  else
    return nil
  end
end
local initialise_repl_code = str.join("__name__ = '__repl__'", "\n")
local function start()
  log.append({(comment_prefix .. "Starting Python client...")})
  if state("repl") then
    return log.append({(comment_prefix .. "Can't start, REPL is already running."), (comment_prefix .. "Stop the REPL with " .. config["get-in"]({"mapping", "prefix"}) .. cfg({"mapping", "stop"}))}, {["break?"] = true})
  else
    local function _21_()
      if vim.treesitter.language.require_language then
        return vim.treesitter.language.require_language("python")
      else
        return vim.treesitter.require_language("python")
      end
    end
    if not pcall(_21_) then
      return log.append({(comment_prefix .. "(error) The python client requires a python treesitter parser in order to function."), (comment_prefix .. "(error) See https://github.com/nvim-treesitter/nvim-treesitter"), (comment_prefix .. "(error) for installation instructions.")})
    else
      local function _23_()
        local function _24_(repl)
          local function _25_(msgs)
            return nil
          end
          return repl.send(prep_code(initialise_repl_code), _25_, nil)
        end
        return display_repl_status("started", with_repl_or_warn(_24_))
      end
      local function _26_(err)
        return display_repl_status(err)
      end
      local function _27_(code, signal)
        log.append({(comment_prefix .. "on-exit: code=>" .. code .. "<, signal=" .. signal)})
        if (("number" == type(code)) and (code > 0)) then
          log.append({(comment_prefix .. "process exited with code " .. code)})
        else
        end
        if (("number" == type(signal)) and (signal > 0)) then
          log.append({(comment_prefix .. "process exited with signal " .. signal)})
        else
        end
        return stop()
      end
      local function _30_(msg)
        return log.dbg(format_msg(unbatch({msg})), {["join-first?"] = true})
      end
      return a.assoc(state(), "repl", stdio.start({["prompt-pattern"] = cfg({"prompt-pattern"}), cmd = cfg({"command"}), ["delay-stderr-ms"] = cfg({"delay-stderr-ms"}), ["on-success"] = _23_, ["on-error"] = _26_, ["on-exit"] = _27_, ["on-stray-output"] = _30_}))
    end
  end
end
local function on_exit()
  log.append({(version .. ".on-exit called")})
  return stop()
end
local function interrupt()
  local function _33_(repl)
    log.append({(comment_prefix .. " Sending interrupt signal.")}, {["break?"] = true})
    return repl["send-signal"](vim.loop.constants.SIGINT)
  end
  return with_repl_or_warn(_33_)
end
local function on_load()
  if config["get-in"]({"client_on_load"}) then
    return start()
  else
    return nil
  end
end
local function on_filetype()
  mapping.buf("PythonStart", cfg({"mapping", "start"}), start, {desc = "Start the Python REPL"})
  mapping.buf("PythonStop", cfg({"mapping", "stop"}), stop, {desc = "Stop the Python REPL"})
  return mapping.buf("PythonInterrupt", cfg({"mapping", "interrupt"}), interrupt, {desc = "Interrupt the current evaluation"})
end
return {["buf-suffix"] = buf_suffix, ["comment-prefix"] = comment_prefix, ["doc-str"] = doc_str, ["eval-file"] = eval_file, ["eval-str"] = eval_str, ["form-node?"] = form_node_3f, ["format-msg"] = format_msg, ["get-help"] = get_help, ["initialise-repl-code"] = initialise_repl_code, interrupt = interrupt, ["is-assignment?"] = is_assignment_3f, ["is-expression?"] = is_expression_3f, ["on-exit"] = on_exit, ["on-filetype"] = on_filetype, ["on-load"] = on_load, start = start, stop = stop, ["str-is-python-expr?"] = str_is_python_expr_3f, unbatch = unbatch, version = version}
