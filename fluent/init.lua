-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")
local CLDR = require("cldr")

-- Internal modules
local FluentSyntax = require("fluent.syntax")
local FluentResource = require("fluent.resource")

local FluentBundle = class()

function FluentBundle:_init (locale)
  self.locales = {}
  self:set_locale(locale)
  -- self:catch(self.get_message)
  return self
end

function FluentBundle:set_locale (locale)
  self.locale = CLDR.locales[locale] and locale or "und"
  if not self.locales[self.locale] then
    self.locales[self.locale] = FluentResource()
  end
  return self:get_locale()
end

function FluentBundle:get_locale ()
  return self.locale
end

function FluentBundle:get_resource (locale)
  local locales = self.locales
  return locales[locale or self:get_locale()]
end

function FluentBundle:get_message (identifier)
  local resource = self:get_resource()
  -- TODO iterate over fallback locales if not found in current one
  return resource:get_message(identifier)
end

function FluentBundle:add_messages (input, locale)
  locale = locale or self:get_locale()
  local syntax = FluentSyntax()
  local messages =
    type(input) == "string"
    and syntax:parsestring(input)
    or tablex.reduce('+', tablex.imap(function (v)
        return syntax:parsestring(v)
      end, input))
  local resource = self:get_resource(locale)
  return resource + messages
end

function FluentBundle:format (identifier, parameters)
  local resource = self:get_resource()
  local message = resource:get_message(identifier)
  return message:format(parameters)
end

return FluentBundle
