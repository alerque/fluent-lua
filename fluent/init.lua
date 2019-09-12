local fluent = {
  locale = nil,
  messages = {}
}

setmetatable(fluent, {
  })

function fluent:set_locale (locale)
  self.locale = locale
end

return fluent
