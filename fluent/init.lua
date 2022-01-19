-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")
local CLDR = require("cldr")

-- Internal modules
local FluentSyntax = require("fluent.syntax")
local FluentResource = require("fluent.resource")

local FluentBundle = class({
    _init = function (self, locale)
      self.locales = {}
      self:set_locale(locale)
      -- Penlight bug #307, should be — self:catch(self.get_message)
      self:catch(function(_, identifier) return self:get_message(identifier) end)
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
      local syntax = FluentSyntax()
      local addittions =
        type(input) == "string"
        and syntax:parsestring(input)
        or tablex.reduce('+', tablex.imap(function (v)
            return syntax:parsestring(v)
          end))
      self.locales[self.locale]:ammend(addittions)
    end,

    format = function (self, identifier, parameters)
      local resource = self.locales[self.locale]
      local message = resource:get_message(identifier)
      -- local message = resource[identifier]
      return message:format(parameters)
    end
  })

return FluentBundle
