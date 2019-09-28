-- External dependencies
local class = require("pl.class")
local epnf = require("epnf")

local nulleof = "NULL\000"
local eol = function () return "\n" end

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
local ftl_eof = epnf.define(function (_ENV)
  eol_eof = 1^0 * P(nulleof) * -1
  START("eol_eof")
end)

local ftl_grammar = epnf.define(function (_ENV)
  local blank_inline = P" "^1
  local line_end = P"\r\n" / eol + P"\n" + P(nulleof)
  blank_block = C((blank_inline^-1 * line_end)^1); local blank_block = V"blank_block"
  local blank = (blank_inline + line_end)^1
  local digits = R"09"^1
  local special_text_char = P"{" + P"}"
  local any_char = R("\0\127") / f1 + R("\194\223") * R(cont) / f2 + R("\224\239") * R(cont) * R(cont) / f3 + R("\240\244") * R(cont) * R(cont) * R(cont) / f4
  local text_char = any_char - special_text_char - line_end
  local special_quoted_char = P'"' + P"\\"
  local special_escape = P"\\" * special_quoted_char
  local unicode_escape = (P"\\u" * P(4) * R("09", "af", "AF")^4) + (P"\\u" * P(6) * R("09", "af", "AF")^6)
  local quoted_char = (any_char - special_quoted_char - line_end) + special_escape + unicode_escape
  local indented_char = text_char - P"{" - P"*" - P"."
  Identifier = Cg(R("az", "AZ") * (R("az", "AZ", "09") + P"_" + P"-")^0, "name")
  variant_list = V"Variant"^0 * V"DefaultVariant" * V"Variant"^0 * line_end
  Variant = line_end * blank^-1 * V"VariantKey" * blank_inline^-1 * V"Pattern"
  DefaultVariant = line_end * blank^-1 * P"*" * V"VariantKey" * blank_inline^-1 * V"Pattern"
  VariantKey = P"[" * blank^-1 * (V"NumberLiteral" + V"Identifier") * blank^-1 * P"]"
  NumberLiteral = Cg(C(P"-"^-1 * digits * (P"." * digits)^-1), "value")
  local inline_placeable = P"{" * blank^-1 * (V"SelectExpression" + V"InlineExpression") * blank^-1 * P"}"
  local block_placeable = blank_block * blank_inline^-1 * inline_placeable
  local inline_text = text_char^1
  local block_text = blank_block * blank_inline * indented_char * inline_text^-1
  StringLiteral = P'"' * Cg(C(quoted_char^0), "value") * P'"'
  FunctionReference = V"Identifier" * V"CallArguments"
  MessageReference = V"Identifier" * V"AttributeAccessor"^-1
  TermReference = P"-" * V"Identifier" * V"AttributeAccessor"^-1 * V"CallArguments"^-1
  _TermReference = P"-" * V"Identifier" * V"AttributeAccessor" * V"CallArguments"^-1
  VariableReference = P"$" * V"Identifier"
  AttributeAccessor = P"." * V"Identifier"
  NamedArgument = V"Identifier" * blank^-1 * P":" * blank^-1 * (V"StringLiteral" + V"NumberLiteral")
  Argument = V"NamedArgument" + V"InlineExpression"
  local argument_list = (V"Argument" * blank^-1 * P"," * blank^-1)^0 * V"Argument"^-1
  CallArguments = blank^-1 * P"(" * blank^-1 * argument_list * blank^-1 * P")"
  InlineExpression = V"StringLiteral" + V"NumberLiteral" + V"FunctionReference" + V"MessageReference" + V"TermReference" + V"VariableReference" + inline_placeable
  _InlineExpression = V"StringLiteral" + V"NumberLiteral" + V"FunctionReference" + V"_TermReference" + V"VariableReference"
  SelectExpression = V"_InlineExpression" * blank^-1 * P"->" * blank_inline^-1 * V"variant_list"
  PatternElement = Cg(C(inline_text + block_text), "value") + Cg(inline_placeable + block_placeable, "expression")
  Pattern = V"PatternElement"^1
  Attribute = line_end * blank^-1 * P"." * V"Identifier" * blank_inline^-1 * "=" * blank_inline^-1 * V"Pattern"
  local junk_line = (1-P"\n"-P(nulleof))^0 * (P"\n" + P(nulleof))
  Junk = Cg(junk_line * (junk_line - P"#" - P"-" - R("az","AZ"))^0, "content")
  local comment_char = any_char - line_end
  CommentLine = Cg(P"###" + P"##" + P"#", "sigil") * (" " * Cg(C(comment_char^0), "content"))^-1 * line_end
  Term = P"-" * V"Identifier" * blank_inline^-1 * "=" * blank_inline^-1 * V"Pattern" * V"Attribute"^0
  Message = V"Identifier" * blank_inline^-1 * P"=" * blank_inline^-1 * ((V"Pattern" * V"Attribute"^0) + V"Attribute"^1)
  Entry = (V"Message" * line_end) + (V"Term" * line_end) + V"CommentLine"
  Resource = (V"Entry" + blank_block + V"Junk")^0 * (P(nulleof) + EOF"unparsable input")
  START("Resource")
end)
-- luacheck: pop

-- TODO: if this doesn't need any state information make in a function not a class
local FluentParser = class({
    _init = function (self, input)
      return type(input) == "string" and self:parsestring(input) or error("unknown input type")
    end,

    addtrailingnewine = function(input)
      local hasnulleof = epnf.parsestring(ftl_eof, input)
      return type(hasnulleof) == "nil" and input..nulleof or input
    end,

    parsestring = function (self, input)
      input = self.addtrailingnewine(input)
      return epnf.parsestring(ftl_grammar, input)
    end
  })

return FluentParser
