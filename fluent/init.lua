-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")

-- Internal modules
local FluentSyntax = require("fluent.syntax")

local FluentBundle = class({
    locale = nil,
    locales = {},
    syntax = FluentSyntax(),

    _init = function (self, locale)
      self.locale = locale
    end,

    add_messages = function (self, input)
      if type(input) == "string" then input = { input } end
      -- TODO: add way to add two resources together, then reduce instead of unpacking this
      local res = table.unpack(tablex.imap(function (v) return self.syntax:parsestring(v) end, input))
      self.locales[self.locale] = res
    end,

    format = function (self, identifier, parameters)
      local res = self.locales[self.locale]
      local msg = res:lookup(identifier)
      return msg:format(parameters)
    end
  })

return FluentBundle
