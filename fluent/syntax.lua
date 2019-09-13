-- External dependencies
local class = require("pl.class")
local epnf = require("epnf")

-- UTF8 code points up to four-byte encodings
local function f1 (s)
  return string.byte(s)
end
local function f2 (s)
  local c1, c2 = string.byte(s, 1, 2)
  return c1 * 64 + c2 - 12416
end
local function f3 (s)
  local c1, c2, c3 = string.byte(s, 1, 3)
  return (c1 * 64 + c2) * 64 + c3 - 925824
end
local function f4 (s)
  local c1, c2, c3, c4 = string.byte(s, 1, 4)
  return ((c1 * 64 + c2) * 64 + c3) * 64 + c4 - 63447168
end
local cont = "\128\191"

-- luacheck: push ignore
local ftlparser = epnf.define(function (_ENV)
  local blank_inline = P" "^1
  local line_end = P"\r\n" + P"\n"
  local blank_block = (blank_inline^-1 * line_end)^1
  local blank = (blank_inline + line_end)^1
  local digits = R"09"^1
  local special_text_char = P"{" + P"}"
  local any_char = R("\0\127") / f1 + R("\194\223") * R(cont) / f2 + R("\224\239") * R(cont) * R(cont) / f3 + R("\240\244") * R(cont) * R(cont) * R(cont) / f4
  local text_char = any_char - special_text_char - line_end
  local indented_char = text_char - P"{" - P"*" - P"."
  Identifier = R("az", "AZ") * (R("az", "AZ", "09") + P"_" + P"-")^0
  InlineExpression = P"foo"
  SelectExpression = P"bar"
  local inline_placeable = P"{" * blank^-1 * (V"SelectExpression" + V"InlineExpression") * blank^-1 * P"}"
  local block_placeable = blank_block * blank_inline^-1 * inline_placeable
  local inline_text = text_char^1
  local block_text = blank_block * blank_inline * indented_char * inline_text^-1
  PatternElement = inline_text + block_text + inline_placeable + block_placeable
  Pattern = V"PatternElement"^1
  Attribute = line_end * blank^-1 * P"." * V"Identifier" * blank_inline^-1 * "=" * blank_inline^-1 * V"Pattern"
  local junk_line =  (1-line_end)^0 * line_end
  Junk = junk_line * (junk_line - P"#" - P"-" - R("az","AZ"))^0
  local comment_char = any_char - line_end
  CommentLine = (P"###" + P"##" + P"#") * (" " * comment_char^0)-1 * line_end
  Term = P"-" * V"Identifier" * blank_inline^-1 * "=" * blank_inline^-1 * V"Pattern" * V"Attribute"^0
  Message = V"Identifier" * blank_inline^-1 * P"=" * blank_inline^-1 * ((V"Pattern" * V"Attribute"^0) + V"Attribute"^1)
  Entry = (V"Message" * line_end) + (V"Term" * line_end) + V"CommentLine"
  Resource = (V"Entry" + blank_block + V"Junk")^0 * EOF"unparsable input"
  START("Resource")
end)
-- luacheck: pop

-- TODO: Spec L53-L82, L122-L129

local FluentSyntax = class({
    parser = ftlparser,
    parse = function (self, input)
      if not self or type(self) ~= "table" then
        error("FluentSyntax.parser error: must be invoked as a method")
      elseif not input or type(input) ~= "string" then
        error("FluentSyntax.parser error: input must be a string")
      end
      local ast = epnf.parsestring(self.parser, input .. "\n")
      return ast
    end
  })

return FluentSyntax
