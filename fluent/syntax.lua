-- External dependencies
local class = require("pl.class")
local epnf = require("epnf")

-- luacheck: push ignore
local ftlparser = epnf.define(function (_ENV)
  START "term"
  term = P"-"
end)
-- luacheck: pop

local FluentSyntax = class({
    parser = ftlparser
  })

return FluentSyntax
