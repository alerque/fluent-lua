-- External dependencies
local class = require("pl.class")
local epnf = require("epnf")
local tablex = require("pl.tablex")

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
local ftlpeg = epnf.define(function (_ENV)
  local blank_inline = P" "^1
  local line_end = P"\r\n" + P"\n"
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
  Junk = Cg(junk_line * (junk_line - P"#" - P"-" - R("az","AZ"))^0, "content")
  local comment_char = any_char - line_end
  CommentLine = Cg(P"###" + P"##" + P"#", "_comment_marker") * (" " * Cg(C(comment_char^0), "content"))^-1 * line_end
  Term = P"-" * V"Identifier" * blank_inline^-1 * "=" * blank_inline^-1 * V"Pattern" * V"Attribute"^0
  Message = V"Identifier" * blank_inline^-1 * P"=" * blank_inline^-1 * ((V"Pattern" * V"Attribute"^0) + V"Attribute"^1)
  Entry = (V"Message" * line_end) + (V"Term" * line_end) + V"CommentLine"
  Resource = (V"Entry" + blank_block + V"Junk")^0 * EOF"unparsable input"
  START("Resource")
end)
-- luacheck: pop

local function ast_props (input)
  local ast = {}
  for key, value in pairs(input) do
    if type(key) == "string" then
      if key == "id" and value ~= "CommentLine" then ast.type = value
      elseif value == "CommentLine" then
      elseif key == "pos" then
      elseif key == "_comment_marker" then
        ast.type = #value == 3 and "ResourceComment" or #value == 2 and "GroupComment" or "Comment"
      else
        ast[key] = value
      end
    end
  end
  return ast
end

local function ast_children (input)
  local children = {}
  for key, value in ipairs(input) do
    if type(key) == "number" then children[key] = value end
  end
  return children
end

-- elseif #content == 0 and type(v) == "number" then
--   content = content .. utf8char(v)

local parse_by_type = {

  Entry = function (self, input)
    local ast = ast_props(input[1])
    tablex.merge(ast, self(input[1]))
    return ast
  end,

  blank_block = function (self, input)
    local _, count = string.gsub(input[1], "\n", "")
    return count >= 1 and {} or nil
  end,

  Junk = function (self, input)
    local stuff = ast_children(input)
    stuff.annotations = {}
    return stuff
  end,

  Message = function (self, input)
    local stuff = ast_children(input)
    return stuff
  end,

  Identifier = function (self, input)
    local stuff = ast_children(input)
    return stuff
  end,

  Term = function (self, input)
    local stuff = ast_children(input)
    return stuff
  end,

  Patterm = function (self, input)
    local stuff = ast_children(input)
    return stuff
  end,

  PatternElement = function (self, input)
    local stuff = ast_children(input)
    return stuff
  end,

  Comment = function (self, input)
    local stuff = ast_children(input)
    return stuff
  end,

  GroupComment = function (self, input)
    local stuff = ast_children(input)
    return stuff
  end,

  ResourceComment = function (self, input)
    local stuff = ast_children(input)
    return stuff
  end,

}

setmetatable(parse_by_type, {
    __call = function (self, input)
      local ast = ast_props(input)
      local stuff = self[ast.type](self, input)
      return stuff and tablex.merge(ast, stuff, true) or nil
    end
  })

local function munge_ast (input)
  local ast = ast_props(input)
  local stash = nil
  ast.body = {}
  local entries = {}
  for key, value in ipairs(input) do
    if type(key) == "number" then
      table.insert(entries, parse_by_type(value))
    end
  end
  local flushcomments = function ()
    if stash then table.insert(ast.body, stash) end
    stash = nil
  end
  local stashcomment = function (input)
    if not stash then
      stash = input
    elseif stash.type == input.type then
      stash.content = (stash.content or "") .. "\n" .. (input.content or "")
    else
      flushcomments()
      stash = input
    end
  end
  for key, value in ipairs(entries) do
    if value.type:match("Comment$") then
      stashcomment(value)
    elseif value.type == "blank_block" then
      flushcomments()
    elseif value.type == "Message" or value.type == "Term" then
      if stash then
        if stash.type ~= "Comment" then
          flushcomments()
        else
          value.comment = stash
          stash = nil
        end
      end
      table.insert(ast.body, value)
    else
      flushcomments()
      table.insert(ast.body, value)
    end
  end
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
      return munge_ast(ast)
    end
    -- TODO: add loader that leverages epnf.parsefile()
  })

return FluentSyntax
