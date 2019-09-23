-- External dependencies
local class = require("pl.class")

-- Internal dependencies
local FluentParser = require("fluent.parser")
local FluentResource = require("fluent.resource")

-- TODO: if this doesn't need any state information make in a function not a class
local FluentSyntax = class({
    resource = nil,

    _init = function (self, input)
      -- TODO: handle file pointers, filnames, tables of pointers?
    end,

    parsestring = function (self, input)
      if not self or type(self) ~= "table" then
        error("FluentSyntax.parse error: must be invoked as a method")
      elseif not input or type(input) ~= "string" then
        error("FluentSyntax.parse error: input must be a string")
      end
      local ast = FluentParser(input)
      return FluentResource(ast)
    end,

    parsefile = function (self, input)
    -- TODO: add loader that leverages epnf.parsefile()
      error("unimplemented")
    end

  })

return FluentSyntax
