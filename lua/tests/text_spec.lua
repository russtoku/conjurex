-- [nfnl] Compiled from fnl/tests/text_spec.fnl by https://github.com/Olical/nfnl, do not edit.
local _local_1_ = require("plenary.busted")
local describe = _local_1_["describe"]
local it = _local_1_["it"]
local assert = require("luassert.assert")
local text = require("conjurex.text")
local function _2_()
  local function _3_()
    local str = "It's so much @%^&*\n () ?./\\"
    local chs = {"I", "t", "'", "s", " ", "s", "o", " ", "m", "u", "c", "h", " ", "@", "%", "^", "&", "*", "\n", " ", "(", ")", " ", "?", ".", "/", "\\"}
    return assert.same(chs, text.chars(str))
  end
  it("chars splits string into characters", _3_)
  do
    local xs = "The rain in Spain falls main on #@$%^!&*\"-+="
    local keep_left = "The rain in S..."
    local keep_right = "... #@$%^!&*\"-+="
    local function _4_()
      return assert.same(keep_left, text["left-sample"](xs, 14))
    end
    it("left-sample keeps the left side", _4_)
    local function _5_()
      return assert.same(keep_right, text["right-sample"](xs, 14))
    end
    it("right-sample keeps the right side", _5_)
  end
  do
    local str1 = "Sunshine on my shoulder\nmakes me happy!"
    local str2 = "Sunshine on my shoulder\n"
    local function _6_()
      return assert.is_not_true(text["ends-with"](str1, "\n"))
    end
    it("ends-with doesn't find character at end of string", _6_)
    local function _7_()
      return assert.is_true(text["ends-with"](str2, "\n"))
    end
    it("ends-with finds character at end of string", _7_)
    local function _8_()
      return assert.is_true(text["ends-with"](str1, "me happy!"))
    end
    it("ends-with finds sub-string at end of string", _8_)
    local function _9_()
      return assert.equals("S!", text["first-and-last-chars"](str1))
    end
    it("first-and-last-chars returns first and last character from string", _9_)
    local function _10_()
      return assert.equals(nil, text["trailing-newline?"](str1))
    end
    it("trailing-newline? returns nil from string without trailing newline", _10_)
    local function _11_()
      return assert.equals("\n", text["trailing-newline?"](str2))
    end
    it("trailing-newline? returns newline from string with trailing newline", _11_)
    local function _12_()
      local str, count = text["trim-last-newline"](str1)
      assert.equals(str1, str)
      return assert.equals(0, count)
    end
    it("trim-last-newline returns 0 from string without trailing newline", _12_)
    local function _13_()
      local str, count = text["trim-last-newline"](str2)
      assert.equals("Sunshine on my shoulder", str)
      return assert.equals(1, count)
    end
    it("trim-last-newline returns 1 when it strips newline from string", _13_)
    local function _14_()
      local function _15_()
        return assert.is_true(text["starts-with"](str1, "S"))
      end
      it("a single character", _15_)
      local function _16_()
        return assert.is_true(text["starts-with"](str1, "Sunshine"))
      end
      it("a word", _16_)
      local function _17_()
        return assert.is_true(text["starts-with"](str1, "Sunshine on"))
      end
      it("two words", _17_)
      local function _18_()
        return assert.is_not_true(text["starts-with"](str1, "Math"))
      end
      return it("doesn't start with a string", _18_)
    end
    describe("starts-with", _14_)
    local function _19_()
      return assert.same({"(out)Sunshine on my shoulder", "(out)makes me happy!"}, text["prefixed-lines"](str1, "(out)"))
    end
    it("prefixed-lines splits and prefixes all lines", _19_)
    local function _20_()
      return assert.same({"Sunshine on my shoulder", "(out)makes me happy!"}, text["prefixed-lines"](str1, "(out)", {["skip-first?"] = true}))
    end
    it("prefixed-lines splits and prefixes all lines except the first", _20_)
  end
  local function _21_()
    return assert.equals("Sunshine", text["upper-first"]("sunshine"))
  end
  it("upper-first returns string with first character capitalized", _21_)
  local function _22_()
    local function _23_()
      return assert.same({""}, text["split-lines"](""))
    end
    it("empty string returns list of one empty string", _23_)
    local function _24_()
      return assert.same({"Sunshine on"}, text["split-lines"]("Sunshine on"))
    end
    it("string without newlines returns list of one string", _24_)
    local function _25_()
      return assert.same({"", ""}, text["split-lines"]("\n"))
    end
    it("string with only newline returns list of two empty strings", _25_)
    local function _26_()
      return assert.same({"Sunshine on", " my shoulder"}, text["split-lines"]("Sunshine on\n my shoulder"))
    end
    it("string with newline returns list of two strings", _26_)
    local function _27_()
      return assert.same({"Sunshine on", " my shoulder", ""}, text["split-lines"]("Sunshine on\n my shoulder\n"))
    end
    return it("string with two newlines returns list of three strings", _27_)
  end
  return describe("split-lines", _22_)
end
return describe("conjurex.text", _2_)
