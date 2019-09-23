-- External dependencies
local class = require("pl.class")

-- Internal modules
local FluentSyntax = require("fluent.syntax")
local FluentMessages = require("messages.syntax")

local FluentBundle = class({
    locale = nil,

    _init = function (self, locale)
      self.locale = locale
      self.messages = FluentMessages()
      self.syntax = FluentSyntax()
    end,

    add_messages = function (self, input)
      for k, v in input:gmatch("(%w+) = (%w+)") do
        self.messages[k] = v
      end
    end,

    format = function (self, key)
      return self.messages[key]
    end
  })

return FluentBundle
