-- External dependencies
local class = require("pl.class")

-- Internal dependencies
local FluentParser = require("fluent.parser")
local FluentResource = require("fluent.resource")

-- TODO: if this doesn't need any state information make it a function not a class
local FluentSyntax = class({

    -- luacheck: ignore 212
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

    parsefile = function (self, fname)
      -- TODO: check if filename or file handle
      if not self or type(self) ~= "table" then
        error("FluentSyntax.parse error: must be invoked as a method")
      elseif not fname or type(fname) ~= "string" then
        error("FluentSyntax.parse error: fname must be a string")
      end
      -- TODO: add loader that leverages epnf.parsefile()
      local f = assert(io.open(fname, "rb"))
      local content = f:read("*all")
      f:close()
      local ast = FluentParser(content)
      return FluentResource(ast)
    end

  })

return FluentSyntax
