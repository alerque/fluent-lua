-- External dependencies
local class = require("pl.class")
local epnf = require("epnf")

-- luacheck: push ignore
local ftlparser = epnf.define(function (_ENV)
  START("Resource")
  Resource = S"-"
end)
-- luacheck: pop

local FluentSyntax = class({
    parser = ftlparser,
    parse = function (self, input)
      local ast = epnf.parsestring(self.parser, input)
      return ast
    end
  })

return FluentSyntax
