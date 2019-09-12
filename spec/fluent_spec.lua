local fluent = require("fluent")

describe('fluent', function ()

  it('should instantiate', function ()
    assert.is.truthy(type(fluent) == "table")
  end)

  it ('should accept a locale', function ()
    local locale = "en-US"
    fluent:set_locale(locale)
    assert.same(locale, fluent.locale)
  end)

end)
