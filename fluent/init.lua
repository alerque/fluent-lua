local class = require("pl.class")

local messages = class({
  })

local fluent = class({
    locale = nil,

    _init = function (self, locale)
      self.locale = locale
      self.messages = messages()
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

return fluent
