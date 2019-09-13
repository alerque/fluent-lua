-- External dependencies
local class = require("pl.class")
local epnf = require("epnf")

-- luacheck: push ignore
local ftlparser = epnf.define(function (_ENV)
  local blank_inline = P" "^1
  local line_end = P"\r\n" + P"\n"
  local blank_block = (blank_inline^-1 * line_end)^1
  local blank = (blank_inline + line_end)^1
  local digits = R"09"^1
  local junk_line =  (1-line_end)^0 * line_end
  Pattern = P"bar" + P"qiz"
  Junk = junk_line * (junk_line - P"#" - P"-" - R("az","AZ"))^0
  Attribute = P"yyy"
  local comment_char = 1 - line_end
  CommentLine = (P"###" + P"##" + P"#") * (" " * comment_char^0)-1 * line_end
  Term = P"xxx"
  Identifier = R("az", "AZ") * (R("az", "AZ", "09") + P"_" + P"-")^0
  Message = V"Identifier" * blank_inline^-1 * P"=" * blank_inline^-1 * ((V"Pattern" * V"Attribute"^0) + V"Attribute"^1)
  Entry = (V"Message" * line_end) + (V"Term" * line_end) + V"CommentLine"
  Resource = (V"Entry" + blank_block + V"Junk")^0 * EOF"unparsable input"
  START("Resource")
end)
-- luacheck: pop

-- TODO: Spec L15-L84, L86-L129

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
