-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")
local CLDR = require("cldr")

-- Internal modules
local FluentSyntax = require("fluent.syntax")
local FluentResource = require("fluent.resource")

local FluentBundle = class({
    syntax = FluentSyntax(),

    _init = function (self, locale)
      self.locales = {}
      self:set_locale(locale)
      -- Penlight bug #307, should be — self:catch(self.get_message)
      self:catch(function(_, k) return self:get_message(k) end)
    end,

    set_locale = function (self, locale)
      self.locale = CLDR.locales[locale] and locale or "und"
      if not self.locales[self.locale] then
        self.locales[self.locale] = FluentResource()
      end
    end,

    get_message = function (self, identifier)
      local locales = rawget(self, "locales")
      -- TODO iterate over fallback locales if not found in current one
      local resource = rawget(locales, self.locale)
      return resource:get_message(identifier) or nil
    end,

    add_messages = function (self, input, locale)
      if locale then self:set_locale(locale) end
      if type(input) == "string" then input = { input } end
      local resources = tablex.imap(function (v) return self.syntax:parsestring(v) end, input)
      local resource = tablex.reduce('+', resources)
      self.locales[self.locale] = tablex.reduce('+', { self.locales[self.locale], resource })
    end,

    format = function (self, identifier, parameters)
      local resource = self.locales[self.locale]
      local message = resource:get_message(identifier)
      -- local message = resource[identifier]
      return message:format(parameters)
    end
  })

return FluentBundle
