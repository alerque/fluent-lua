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

local nulleof = "NULL\000"

-- luacheck: push ignore
local ftleof = epnf.define(function (_ENV)
  eol_eof = 1^0 * P(nulleof) * -1
  START("eol_eof")
end)

local nl = function ()
  return "\n"
end

local ftlpeg = epnf.define(function (_ENV)
  local blank_inline = P" "^1
  local line_end = P"\r\n" / nl + P"\n" + P(nulleof)
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
  PatternElement = Cg(C(inline_text + block_text + inline_placeable + block_placeable), "value")
  Pattern = V"PatternElement"^1
  Attribute = line_end * blank^-1 * P"." * V"Identifier" * blank_inline^-1 * "=" * blank_inline^-1 * V"Pattern"
  local junk_line =  (1-line_end)^0 * (P"\n" + P(nulleof))
  Junk = Cg(junk_line * (junk_line - P"#" - P"-" - R("az","AZ"))^0, "content")
  local comment_char = any_char - line_end
  CommentLine = Cg(P"###" + P"##" + P"#", "_comment_marker") * (" " * Cg(C(comment_char^0), "content"))^-1 * line_end
  Term = P"-" * V"Identifier" * blank_inline^-1 * "=" * blank_inline^-1 * V"Pattern" * V"Attribute"^0
  Message = V"Identifier" * blank_inline^-1 * P"=" * blank_inline^-1 * ((V"Pattern" * V"Attribute"^0) + V"Attribute"^1)
  Entry = (V"Message" * line_end) + (V"Term" * line_end) + V"CommentLine"
  Resource = (V"Entry" + blank_block + V"Junk")^0 * (P(nulleof) + EOF"unparsable input")
  START("Resource")
end)
-- luacheck: pop

local function ast_props (node)
  local ast = {}
  for key, value in pairs(node) do
    if type(key) == "string" then
      if key == "id" and value ~= "CommentLine" then ast.type = value
      elseif value == "CommentLine" then
      elseif key == "pos" then
      elseif key == "_comment_marker" then
        ast.type = #value == 3 and "ResourceComment" or #value == 2 and "GroupComment" or "Comment"
      elseif key == "value" then
        local value = string.gsub(value, "^\n+ +", "")
        ast[key] = value
      else
        ast[key] = value
      end
    end
  end
  return ast
end

local function ast_children (node)
  local children = {}
  for key, value in ipairs(node) do
    if type(key) == "number" then children[key] = value end
  end
  return children
end

local parse_by_type = {

  Entry = function (self, node)
    return self(node[1])
  end,

  blank_block = function (self, node)
    local _, count = string.gsub(node[1], "\n", "")
    return count >= 1 and {} or nil
  end,

  Junk = function (self, node)
    node = ast_children(node)
    node.annotations = {}
    return node
  end,

  Message = function (self, node)
    node = ast_children(node)
    local ast = { id = node.id, value = {}, attributes = {} }
    for key, value in ipairs(node) do
      if value.id == "Identifier" then
        ast.id = self(value)
      elseif value.id == "Pattern" then
        ast.value = self(value)
      end
    end
    return ast
  end,

  Identifier = function (self, node)
    return ast_children(node)
  end,

  Term = function (self, node)
    return self:Message(node)
  end,

  Pattern = function (self, node)
    local stuff = ast_children(node)
    local ast = { elements = {} }
    for key, value in ipairs(stuff) do
      table.insert(ast.elements, self(value))
    end
    return ast
  end,

  PatternElement = function (self, node)
    node = ast_children(node)
    node.type = "TextElement"
    return node
  end,

  Comment = function (self, node)
    return ast_children(node)
  end,

  GroupComment = function (self, node)
    return ast_children(node)
  end,

  ResourceComment = function (self, node)
    return ast_children(node)
  end,

}

setmetatable(parse_by_type, {
    __call = function (self, node)
      local ast = ast_props(node)
      local stuff = self[ast.type](self, node)
      return stuff and tablex.merge(ast, stuff, true) or nil
    end
  })

local function munge_ast (node)
  local ast = ast_props(node)
  local stash = nil
  ast.body = {}
  local entries = {}
  for key, value in ipairs(node) do
    if type(key) == "number" then
      table.insert(entries, parse_by_type(value))
    end
  end
  local flushcomments = function ()
    if stash then table.insert(ast.body, stash) end
    stash = nil
  end
  local stashcomment = function (node)
    if not stash then
      stash = node
    elseif stash.type == node.type then
      stash.content = (stash.content or "") .. "\n" .. (node.content or "")
    else
      flushcomments()
      stash = node
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
  flushcomments()
  return ast
end

local FluentSyntax = class({
    addtrailingnewine = function(input)
      local hasnulleof = epnf.parsestring(ftleof, input)
      return type(hasnulleof) == "nil" and input..nulleof or input
    end,

    parse = function (self, input)
      if not self or type(self) ~= "table" then
        error("FluentSyntax.parser error: must be invoked as a method")
      elseif not input or type(input) ~= "string" then
        error("FluentSyntax.parser error: input must be a string")
      end
      input = self.addtrailingnewine(input)
      local ast = epnf.parsestring(ftlpeg, input)
      return munge_ast(ast)
    end
    -- TODO: add loader that leverages epnf.parsefile()
  })

return FluentSyntax
