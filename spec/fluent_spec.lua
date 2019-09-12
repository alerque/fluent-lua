local fluent = require("fluent")

describe('fluent', function ()

  it('should instantiate with a locale', function ()
    local locale = "en-US"
    local bundle = fluent(locale)
    assert.is.truthy(bundle:is_a(fluent))
    assert.same(locale, bundle.locale)
  end)

end)
