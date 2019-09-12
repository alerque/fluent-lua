local class = require("pl.class")

local fluent = class({
  locale = nil,
  messages = {},

  _init = function (self, locale)
    self.locale = locale
  end
})

return fluent
