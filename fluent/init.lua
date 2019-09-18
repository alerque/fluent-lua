-- luacheck: ignore D
local D = require("pl.pretty").dump

-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")
local CLDR = require("cldr")

-- Internal modules
local FluentSyntax = require("fluent.syntax")

local FluentBundle = class({
    locale = nil,
    locales = {},
    syntax = FluentSyntax(),

    _init = function (self, locale)
      self.locale = CLDR.locales[locale] and locale or "und"
      self.locales = {}
      -- Penlight bug #307, should be — self:catch(self.get_message)
      self:catch(function(_, k) return self:get_message(k) end)
    end,

    set_locale = function (self, locale)
      self.locale = CLDR.locales[locale] and locale or "und"
    end,

    get_message = function (self, identifier)
      local locale = rawget(self, "locale")
      local locales = rawget(self, "locales")
      local default = rawget(locales, locale)
      -- TODO iterate over fallback locales if not found in default
      return default and default[identifier] or nil
    end,

    add_messages = function (self, input, locale)
      if type(input) == "string" then input = { input } end
      local resources = tablex.imap(function (v) return self.syntax:parsestring(v) end, input)
      local resource = tablex.reduce('+', resources)
      self.locales[locale or self.locale] = resource
    end,

    format = function (self, identifier, parameters)
      local resource = self.locales[self.locale]
      local message = resource:get_message(identifier)
      -- local message = resource[identifier]
      return message:format(parameters)
    end
  })

return FluentBundle
