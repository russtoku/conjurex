-- [nfnl] Compiled from fnl/conjurex/log.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("nfnl.module")
local autoload = _local_1_["autoload"]
local a = autoload("nfnl.core")
local buffer = autoload("conjure.buffer")
local client = autoload("conjurex.client")
local config = autoload("conjure.config")
local editor = autoload("conjure.editor")
local hook = autoload("conjure.hook")
local sponsors = require("conjure.sponsors")
local str = autoload("nfnl.string")
local text = autoload("conjurex.text")
local timer = autoload("conjure.timer")
local version = "conjurex.log"
local state = {["last-open-cmd"] = "vsplit", hud = {id = nil, timer = nil, ["created-at-ms"] = 0, ["low-priority-spam"] = {streak = 0, ["help-displayed?"] = false}}, ["jump-to-latest"] = {mark = nil, ns = vim.api.nvim_create_namespace("conjure_log_jump_to_latest")}}
local function _break()
  return str.join({client.get("comment-prefix"), string.rep("-", config["get-in"]({"log", "break_length"}))})
end
local function state_key_header()
  return str.join({client.get("comment-prefix"), "State: ", client["state-key"]()})
end
local function log_buf_name()
  return str.join({"conjure-log-", vim.fn.getpid(), client.get("buf-suffix")})
end
local function log_buf_3f(name)
  return text["ends-with"](name, log_buf_name())
end
local function on_new_log_buf(buf)
  state["jump-to-latest"].mark = vim.api.nvim_buf_set_extmark(buf, state["jump-to-latest"].ns, 0, 0, {})
  if (vim.diagnostic and (false == config["get-in"]({"log", "diagnostics"}))) then
    if (1 == vim.fn.has("nvim-0.10")) then
      vim.diagnostic.enable(false, {bufnr = buf})
    else
      vim.diagnostic.disable(buf)
    end
  else
  end
  if (vim.treesitter and (false == config["get-in"]({"log", "treesitter"}))) then
    vim.treesitter.stop(buf)
    vim.api.nvim_buf_set_option(buf, "syntax", "on")
  else
  end
  return vim.api.nvim_buf_set_lines(buf, 0, -1, false, {str.join({client.get("comment-prefix"), "Sponsored by @", a.get(sponsors, a.inc(math.floor(a.rand(a.dec(a.count(sponsors)))))), " \226\157\164"})})
end
local function upsert_buf()
  return buffer["upsert-hidden"](log_buf_name(), client.wrap(on_new_log_buf))
end
local function clear_close_hud_passive_timer()
  return a["update-in"](state, {"hud", "timer"}, timer.destroy)
end
local function _5_()
  if state.hud.id then
    pcall(vim.api.nvim_win_close, state.hud.id, true)
    state.hud.id = nil
    return nil
  else
    return nil
  end
end
hook.define("close-hud", _5_)
local function close_hud()
  clear_close_hud_passive_timer()
  return hook.exec("close-hud")
end
local function hud_lifetime_ms()
  return (vim.loop.now() - state.hud["created-at-ms"])
end
local function close_hud_passive()
  if (state.hud.id and (hud_lifetime_ms() > config["get-in"]({"log", "hud", "minimum_lifetime_ms"}))) then
    local original_timer_id = state.hud["timer-id"]
    local delay = config["get-in"]({"log", "hud", "passive_close_delay"})
    if (0 == delay) then
      return close_hud()
    else
      if not a["get-in"](state, {"hud", "timer"}) then
        return a["assoc-in"](state, {"hud", "timer"}, timer.defer(close_hud, delay))
      else
        return nil
      end
    end
  else
    return nil
  end
end
local function break_lines(buf)
  local break_str = _break()
  local function _11_(_10_)
    local n = _10_[1]
    local s = _10_[2]
    return (s == break_str)
  end
  return a.map(a.first, a.filter(_11_, a["kv-pairs"](vim.api.nvim_buf_get_lines(buf, 0, -1, false))))
end
local function set_win_opts_21(win)
  local _12_
  if config["get-in"]({"log", "wrap"}) then
    _12_ = true
  else
    _12_ = false
  end
  vim.api.nvim_set_option_value("wrap", _12_, {win = win})
  vim.api.nvim_set_option_value("foldmethod", "marker", {scope = "local"})
  vim.api.nvim_set_option_value("foldmarker", (config["get-in"]({"log", "fold", "marker", "start"}) .. "," .. config["get-in"]({"log", "fold", "marker", "end"})), {scope = "local"})
  return vim.api.nvim_set_option_value("foldlevel", 0, {scope = "local"})
end
local function in_box_3f(box, pos)
  return ((pos.x >= box.x1) and (pos.x <= box.x2) and (pos.y >= box.y1) and (pos.y <= box.y2))
end
local function flip_anchor(anchor, n)
  local chars = {anchor:sub(1, 1), anchor:sub(2)}
  local flip = {N = "S", S = "N", E = "W", W = "E"}
  local function _14_(_241)
    return a.get(flip, _241)
  end
  return str.join(a.update(chars, n, _14_))
end
local function pad_box(box, padding)
  local function _15_(_241)
    return (_241 - padding.x)
  end
  local function _16_(_241)
    return (_241 - padding.y)
  end
  local function _17_(_241)
    return (_241 + padding.x)
  end
  local function _18_(_241)
    return (_241 + padding.y)
  end
  return a.update(a.update(a.update(a.update(box, "x1", _15_), "y1", _16_), "x2", _17_), "y2", _18_)
end
local function hud_window_pos(anchor, size, rec_3f)
  local north = 0
  local west = 0
  local south = (editor.height() - 2)
  local east = editor.width()
  local padding_percent = config["get-in"]({"log", "hud", "overlap_padding"})
  local pos
  local _19_
  if ("NE" == anchor) then
    _19_ = {row = north, col = east, box = {y1 = north, x1 = (east - size.width), y2 = (north + size.height), x2 = east}}
  elseif ("SE" == anchor) then
    _19_ = {row = south, col = east, box = {y1 = (south - size.height), x1 = (east - size.width), y2 = south, x2 = east}}
  elseif ("SW" == anchor) then
    _19_ = {row = south, col = west, box = {y1 = (south - size.height), x1 = west, y2 = south, x2 = (west + size.width)}}
  elseif ("NW" == anchor) then
    _19_ = {row = north, col = west, box = {y1 = north, x1 = west, y2 = (north + size.height), x2 = (west + size.width)}}
  else
    vim.api.nvim_err_writeln("g:conjure#log#hud#anchor must be one of: NE, SE, SW, NW")
    _19_ = hud_window_pos("NE", size)
  end
  pos = a.assoc(_19_, "anchor", anchor)
  if (not rec_3f and in_box_3f(pad_box(pos.box, {x = editor["percent-width"](padding_percent), y = editor["percent-height"](padding_percent)}), {x = editor["cursor-left"](), y = editor["cursor-top"]()})) then
    local function _21_()
      if (size.width > size.height) then
        return 1
      else
        return 2
      end
    end
    return hud_window_pos(flip_anchor(anchor, _21_()), size, true)
  else
    return pos
  end
end
local function current_window_floating_3f()
  return ("number" == type(a.get(vim.api.nvim_win_get_config(0), "zindex")))
end
local low_priority_streak_threshold = 5
local function handle_low_priority_spam_21(low_priority_3f)
  if not a["get-in"](state, {"hud", "low-priority-spam", "help-displayed?"}) then
    if low_priority_3f then
      a["update-in"](state, {"hud", "low-priority-spam", "streak"}, a.inc)
    else
      a["assoc-in"](state, {"hud", "low-priority-spam", "streak"}, 0)
    end
    if (a["get-in"](state, {"hud", "low-priority-spam", "streak"}) > low_priority_streak_threshold) then
      do
        local pref = client.get("comment-prefix")
        client.schedule(require("conjure.log").append, {(pref .. "Is the HUD popping up too much and annoying you in this project?"), (pref .. "Set this option to suppress this kind of output for this session."), (pref .. "  :let g:conjure#log#hud#ignore_low_priority = v:true")}, {["break?"] = true})
      end
      return a["assoc-in"](state, {"hud", "low-priority-spam", "help-displayed?"}, true)
    else
      return nil
    end
  else
    return nil
  end
end
local function _26_(opts)
  local buf = upsert_buf()
  local last_break = a.last(break_lines(buf))
  local line_count = vim.api.nvim_buf_line_count(buf)
  local size = {width = editor["percent-width"](config["get-in"]({"log", "hud", "width"})), height = editor["percent-height"](config["get-in"]({"log", "hud", "height"}))}
  local pos = hud_window_pos(config["get-in"]({"log", "hud", "anchor"}), size)
  local border = config["get-in"]({"log", "hud", "border"})
  local win_opts = a.merge({relative = "editor", row = pos.row, col = pos.col, anchor = pos.anchor, width = size.width, height = size.height, style = "minimal", zindex = config["get-in"]({"log", "hud", "zindex"}), border = border, focusable = false})
  if (state.hud.id and not vim.api.nvim_win_is_valid(state.hud.id)) then
    close_hud()
  else
  end
  if state.hud.id then
    vim.api.nvim_win_set_buf(state.hud.id, buf)
  else
    handle_low_priority_spam_21(a.get(opts, "low-priority?"))
    state.hud.id = vim.api.nvim_open_win(buf, false, win_opts)
    set_win_opts_21(state.hud.id)
  end
  state.hud["created-at-ms"] = vim.loop.now()
  if last_break then
    vim.api.nvim_win_set_cursor(state.hud.id, {1, 0})
    return vim.api.nvim_win_set_cursor(state.hud.id, {math.min((last_break + a.inc(math.floor((win_opts.height / 2)))), line_count), 0})
  else
    return vim.api.nvim_win_set_cursor(state.hud.id, {line_count, 0})
  end
end
hook.define("display-hud", _26_)
local function display_hud(opts)
  if (config["get-in"]({"log", "hud", "enabled"}) and not current_window_floating_3f() and (not config["get-in"]({"log", "hud", "ignore_low_priority"}) or (config["get-in"]({"log", "hud", "ignore_low_priority"}) and not a.get(opts, "low-priority?")))) then
    clear_close_hud_passive_timer()
    return hook.exec("display-hud", opts)
  else
    return nil
  end
end
local function win_visible_3f(win)
  return (vim.fn.tabpagenr() == a.first(vim.fn.win_id2tabwin(win)))
end
local function with_buf_wins(buf, f)
  local function _31_(win)
    if (buf == vim.api.nvim_win_get_buf(win)) then
      return f(win)
    else
      return nil
    end
  end
  return a["run!"](_31_, vim.api.nvim_list_wins())
end
local function win_botline(win)
  return a.get(a.first(vim.fn.getwininfo(win)), "botline")
end
local function trim(buf)
  local line_count = vim.api.nvim_buf_line_count(buf)
  if (line_count > config["get-in"]({"log", "trim", "at"})) then
    local target_line_count = (line_count - config["get-in"]({"log", "trim", "to"}))
    local break_line
    local function _33_(line)
      if (line >= target_line_count) then
        return line
      else
        return nil
      end
    end
    break_line = a.some(_33_, break_lines(buf))
    if break_line then
      vim.api.nvim_buf_set_lines(buf, 0, break_line, false, {})
      local line_count0 = vim.api.nvim_buf_line_count(buf)
      local function _35_(win)
        local _let_36_ = vim.api.nvim_win_get_cursor(win)
        local row = _let_36_[1]
        local col = _let_36_[2]
        vim.api.nvim_win_set_cursor(win, {1, 0})
        return vim.api.nvim_win_set_cursor(win, {row, col})
      end
      return with_buf_wins(buf, _35_)
    else
      return nil
    end
  else
    return nil
  end
end
local function last_line(buf, extra_offset)
  return a.first(vim.api.nvim_buf_get_lines((buf or upsert_buf()), (-2 + (extra_offset or 0)), -1, false))
end
local cursor_scroll_position__3ecommand = {top = "normal zt", center = "normal zz", bottom = "normal zb", none = nil}
local function jump_to_latest()
  local buf = upsert_buf()
  local last_eval_start = vim.api.nvim_buf_get_extmark_by_id(buf, state["jump-to-latest"].ns, state["jump-to-latest"].mark, {})
  local function _39_(win)
    local function _40_()
      return vim.api.nvim_win_set_cursor(win, last_eval_start)
    end
    pcall(_40_)
    local cmd = a.get(cursor_scroll_position__3ecommand, config["get-in"]({"log", "jump_to_latest", "cursor_scroll_position"}))
    if cmd then
      local function _41_()
        return vim.api.nvim_command({cmd = cmd}, {})
      end
      return vim.api.nvim_win_call(win, _41_)
    else
      return nil
    end
  end
  return with_buf_wins(buf, _39_)
end
vim.api.nvim_command("pwd")
vim.api.nvim_cmd({cmd = "pwd"}, {})
vim.api.nvim_cmd({cmd = "pwd"}, {output = true})
local function append(lines, opts)
  local line_count = a.count(lines)
  if (line_count > 0) then
    local visible_scrolling_log_3f = false
    local buf = upsert_buf()
    local join_first_3f = a.get(opts, "join-first?")
    local lines0
    local function _43_(line)
      return string.gsub(tostring(line), "\n", "\226\134\181")
    end
    lines0 = a.map(_43_, lines)
    local lines1
    if (line_count <= config["get-in"]({"log", "strip_ansi_escape_sequences_line_limit"})) then
      lines1 = a.map(text["strip-ansi-escape-sequences"], lines0)
    else
      lines1 = lines0
    end
    local comment_prefix = client.get("comment-prefix")
    local fold_marker_end = str.join({comment_prefix, config["get-in"]({"log", "fold", "marker", "end"})})
    local lines2
    if (not a.get(opts, "break?") and not join_first_3f and config["get-in"]({"log", "fold", "enabled"}) and (a.count(lines1) >= config["get-in"]({"log", "fold", "lines"}))) then
      lines2 = a.concat({str.join({comment_prefix, config["get-in"]({"log", "fold", "marker", "start"}), " ", text["left-sample"](str.join("\n", lines1), editor["percent-width"](config["get-in"]({"preview", "sample_limit"})))})}, lines1, {fold_marker_end})
    else
      lines2 = lines1
    end
    local last_fold_3f = (fold_marker_end == last_line(buf))
    local lines3
    if a.get(opts, "break?") then
      local _46_
      if client["multiple-states?"]() then
        _46_ = {state_key_header()}
      else
        _46_ = nil
      end
      lines3 = a.concat({_break()}, _46_, lines2)
    elseif join_first_3f then
      local _48_
      if last_fold_3f then
        _48_ = {(last_line(buf, -1) .. a.first(lines2)), fold_marker_end}
      else
        _48_ = {(last_line(buf) .. a.first(lines2))}
      end
      lines3 = a.concat(_48_, a.rest(lines2))
    else
      lines3 = lines2
    end
    local old_lines = vim.api.nvim_buf_line_count(buf)
    do
      local ok_3f, err = nil, nil
      local function _51_()
        local _52_
        if buffer["empty?"](buf) then
          _52_ = 0
        elseif join_first_3f then
          if last_fold_3f then
            _52_ = -3
          else
            _52_ = -2
          end
        else
          _52_ = -1
        end
        return vim.api.nvim_buf_set_lines(buf, _52_, -1, false, lines3)
      end
      ok_3f, err = pcall(_51_)
      if not ok_3f then
        error(("Conjure failed to append to log: " .. err .. "\n" .. "Offending lines: " .. a["pr-str"](lines3)))
      else
      end
    end
    do
      local new_lines = vim.api.nvim_buf_line_count(buf)
      local jump_to_latest_3f = config["get-in"]({"log", "jump_to_latest", "enabled"})
      local _56_
      if join_first_3f then
        _56_ = old_lines
      else
        _56_ = a.inc(old_lines)
      end
      vim.api.nvim_buf_set_extmark(buf, state["jump-to-latest"].ns, _56_, 0, {id = state["jump-to-latest"].mark})
      local function _58_(win)
        visible_scrolling_log_3f = ((win ~= state.hud.id) and win_visible_3f(win) and (jump_to_latest_3f or (win_botline(win) >= old_lines)))
        local _let_59_ = vim.api.nvim_win_get_cursor(win)
        local row = _let_59_[1]
        local _ = _let_59_[2]
        if jump_to_latest_3f then
          return jump_to_latest()
        elseif (row == old_lines) then
          return vim.api.nvim_win_set_cursor(win, {new_lines, 0})
        else
          return nil
        end
      end
      with_buf_wins(buf, _58_)
    end
    if (not a.get(opts, "suppress-hud?") and not visible_scrolling_log_3f) then
      display_hud(opts)
    else
      close_hud()
    end
    return trim(buf)
  else
    return nil
  end
end
local function create_win(cmd)
  state["last-open-cmd"] = cmd
  local buf = upsert_buf()
  local _63_
  if config["get-in"]({"log", "botright"}) then
    _63_ = "botright "
  else
    _63_ = ""
  end
  vim.api.nvim_cmd({cmd = ("keepalt " .. _63_ .. cmd .. " " .. buffer.resolve(log_buf_name()))}, {})
  vim.api.nvim_win_set_cursor(0, {vim.api.nvim_buf_line_count(buf), 0})
  set_win_opts_21(0)
  return buffer.unlist(buf)
end
local function split()
  return create_win("split")
end
local function vsplit()
  return create_win("vsplit")
end
local function tab()
  return create_win("tabnew")
end
local function buf()
  return create_win("buf")
end
local function find_windows()
  local buf0 = upsert_buf()
  local function _65_(win)
    return ((state.hud.id ~= win) and (buf0 == vim.api.nvim_win_get_buf(win)))
  end
  return a.filter(_65_, vim.api.nvim_tabpage_list_wins(0))
end
local function close(windows)
  local function _66_(_241)
    return vim.api.nvim_win_close(_241, true)
  end
  return a["run!"](_66_, windows)
end
local function close_visible()
  close_hud()
  return close(find_windows())
end
local function toggle()
  local windows = find_windows()
  if a["empty?"](windows) then
    if ((state["last-open-cmd"] == "split") or (state["last-open-cmd"] == "vsplit")) then
      return create_win(state["last-open-cmd"])
    else
      return nil
    end
  else
    return close_visible(windows)
  end
end
local function dbg(desc, ...)
  if config["get-in"]({"debug"}) then
    append(a.concat({(client.get("comment-prefix") .. "debug: " .. desc)}, text["split-lines"](a["pr-str"](...))))
  else
  end
  return ...
end
local function reset_soft()
  return on_new_log_buf(upsert_buf())
end
local function reset_hard()
  return vim.cmd({cmd = "bwipeout", args = upsert_buf(), bang = true})
end
return {append = append, buf = buf, ["clear-close-hud-passive-timer"] = clear_close_hud_passive_timer, ["close-hud"] = close_hud, ["close-hud-passive"] = close_hud_passive, ["close-visible"] = close_visible, ["cursor-scroll-position->command"] = cursor_scroll_position__3ecommand, dbg = dbg, ["hud-lifetime-ms"] = hud_lifetime_ms, ["jump-to-latest"] = jump_to_latest, ["last-line"] = last_line, ["log-buf?"] = log_buf_3f, ["reset-hard"] = reset_hard, ["reset-soft"] = reset_soft, split = split, tab = tab, toggle = toggle, version = version, vsplit = vsplit}