local class = require("pl.class")

local fluent = class({
  locale = nil,
  messages = {},

  _init = function (self, locale)
    self.locale = locale
  end,

  add_messages = function (self, input)
    for k, v in input:gmatch("(%w+) = (%w+)") do
      self.messages[k] = v
    end
  end
})

return fluent
