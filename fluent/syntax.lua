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

-- Straight out of SILE.utilities
local function utf8char (c)
    if     c < 128 then
        return string.char(c)
    elseif c < 2048 then
        return string.char(math.floor(192 + c/64), 128 + c%64)
    elseif c < 55296 or 57343 < c and c < 65536 then
        return  string.char(math.floor(224 + c/4096), math.floor(128 + c/64%64), 128 + c%64)
    elseif c < 1114112 then
        return string.char(math.floor(240 + c/262144), math.floor(128 + c/4096%64), math.floor(128 + c/64%64), 128 + c%64)
    end
end

-- luacheck: push ignore
local ftlpeg = epnf.define(function (_ENV)
  local blank_inline = P" "^1
  local line_end = P"\r\n" + P"\n"
  local blank_block = (blank_inline^-1 * line_end)^1
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
  Identifier = R("az", "AZ") * (R("az", "AZ", "09") + P"_" + P"-")^0
  local variant_list = V"Variant"^0 * V"DefaultVariant" * V"Variant" * line_end
  Variant = line_end * blank^-1 * V"VariantKey" * blank_inline^-1 * V"Pattern"
  DefaultVariant = line_end * blank^-1 * P"*" * V"VariantKey" * blank_inline^-1 * V"Pattern"
  VariantKey = P"[" * blank^-1 * (V"NumberLiteral" + V"Identifier") * blank^-1 * P"]"
  NumberLiteral = P"-"^-1 * digits * (P"." * digits)^-1
  local inline_placeable = P"{" * blank^-1 * (V"SelectExpression" + V"InlineExpression") * blank^-1 * P"}"
  local block_placeable = blank_block * blank_inline^-1 * inline_placeable
  local inline_text = text_char^1
  local block_text = blank_block * blank_inline * indented_char * inline_text^-1
  StringLiteral = P'"' * quoted_char^0 * P'"'
  FunctionReference = V"Identifier" * V"CallArguments"
  MessageReference = V"Identifier" * V"AttributeAccessor"^-1
  TermReference = P"-" * V"Identifier" * V"AttributeAccessor"^-1 * V"CallArguments"^-1
  VariableReference = P"$" * V"Identifier"
  AttributeAccessor = P"." * V"Identifier"
  NamedArgument = V"Identifier" * blank^-1 * P":" * blank^-1 * (V"StringLiteral" + V"NumberLiteral")
  Argument = V"NamedArgument" + V"InlineExpression"
  local argument_list = (V"Argument" * blank^-1 * P"," * blank^-1)^0 * V"Argument"^-1
  CallArguments = blank^-1 * P"(" * blank^-1 * argument_list * blank^-1 * P")"
  SelectExpression = V"InlineExpression" * blank^-1 * P"->" * blank_inline^-1 * variant_list
  InlineExpression = V"StringLiteral" + V"NumberLiteral" + V"FunctionReference" + V"MessageReference" + V"TermReference" + V"VariableReference" + inline_placeable
  PatternElement = inline_text + block_text + inline_placeable + block_placeable
  Pattern = V"PatternElement"^1
  Attribute = line_end * blank^-1 * P"." * V"Identifier" * blank_inline^-1 * "=" * blank_inline^-1 * V"Pattern"
  local junk_line =  (1-line_end)^0 * line_end
  Junk = C(junk_line * (junk_line - P"#" - P"-" - R("az","AZ"))^0)
  local comment_char = any_char - line_end
  CommentLine = (P"###" + P"##" + P"#") * (" " * C(comment_char^0))-1 * line_end
  Term = P"-" * V"Identifier" * blank_inline^-1 * "=" * blank_inline^-1 * V"Pattern" * V"Attribute"^0
  Message = V"Identifier" * blank_inline^-1 * P"=" * blank_inline^-1 * ((V"Pattern" * V"Attribute"^0) + V"Attribute"^1)
  Entry = (V"Message" * line_end) + (V"Term" * line_end) + V"CommentLine"
  Resource = (V"Entry" + blank_block + V"Junk")^0 * EOF"unparsable input"
  START("Resource")
end)
-- luacheck: pop

local function mungeast (input, parent)
  -- if true then return input end
  local ast = { }
  local elements = {}
  local content = ""
  for k, v in pairs(input) do
    if type(k) == "number" then
      if k == 1 and type(v) == "string" then
        d(v)
        content = v
      elseif type(v) == "table" then
        elements[k] = mungeast(v, input["id"])
      elseif #content == 0 and type(v) == "number" then
        content = content .. utf8char(v)
      elseif #content > 0 and type(v) == "number" then
        -- Captured as string
      else error ("what the ast element "..type(v))
      end
    elseif type(k) == "string" then
      if k == "id" then ast["type"] = v
      elseif k == "pos" then
      else error("what the ast key "..k)
      end
    else error("what the ast datatype "..type(k))
    end
  end
  if ast["type"] == "Resource" then
    ast.body = elements
  elseif ast["type"] == "Junk" then
    ast.annotations = {}
  elseif ast["type"] == "Entry" then
    ast = elements
  elseif ast["type"] == "Message" then
    ast = elements
  elseif ast["type"] == "CommentLine" then
    ast["type"] = "Comment"
  -- else error("what the type "..ast["type"])
  end
  if #content > 0 then ast.content = content end
  return ast
end

local FluentSyntax = class({
    parse = function (self, input)
      if not self or type(self) ~= "table" then
        error("FluentSyntax.parser error: must be invoked as a method")
      elseif not input or type(input) ~= "string" then
        error("FluentSyntax.parser error: input must be a string")
      end
      local ast = epnf.parsestring(ftlpeg, input .. "\n")
      return mungeast(ast)
    end
    -- TODO: add loader that leverages epnf.parsefile()
  })

return FluentSyntax
