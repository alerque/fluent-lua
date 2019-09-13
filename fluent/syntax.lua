-- External dependencies
local class = require("pl.class")
local epnf = require("epnf")

-- luacheck: push ignore
local ftlparser = epnf.define(function (_ENV)
  START("Resource")
  Resource = P""
end)
-- luacheck: pop

local FluentSyntax = class({
    parser = ftlparser,
    parse = function (self, input)
      if not self or type(self) ~= "table" then
        error("FluentSyntax.parser error: must be invoked as a method")
      end
      if not input or type(input) ~= "string" then
        error("FluentSyntax.parser error: input must be a string")
      end
      local ast = epnf.parsestring(self.parser, input)
      return ast
    end
  })

return FluentSyntax
