-- External dependencies
local class = require("pl.class")

-- Internal dependencies
local FluentParser = require("fluent.parser")
local FluentAST = require("fluent.ast")

local FluentSyntax = class({
    parser = FluentParser(),
    ast = FluentAST(),

    -- TODO: add loader that leverages epnf.parsefile()
    parse = function (self, input)
      if not self or type(self) ~= "table" then
        error("FluentSyntax.parse error: must be invoked as a method")
      elseif not input or type(input) ~= "string" then
        error("FluentSyntax.parse error: input must be a string")
      end
      local ast = self.parser:parsestring(input)
      return self:munge(ast)
    end,

    munge = function (self, ast)
      return self.ast:munge(ast)
    end
  })

return FluentSyntax
