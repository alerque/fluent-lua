local fluent = require("fluent")

describe('fluent', function ()

  it('should instantiate with a locale', function ()
    local locale = "en-US"
    local bundle = fluent(locale)
    assert.is.truthy(bundle:is_a(fluent))
    assert.same(locale, bundle.locale)
  end)

  it('should parse single simple messages', function ()
    local locale = "en-US"
    local bundle = fluent(locale)
    bundle:add_messages("foo = bar")
    assert.same("bar", bundle.messages.foo)
  end)

  it('should parse multiple simple messages', function ()
    local locale = "en-US"
    local bundle = fluent(locale)
    bundle:add_messages("foo = bar\nbar = baz")
    assert.same("bar", bundle.messages.foo)
    assert.same("baz", bundle.messages.bar)
  end)

  it('should return formatted strings', function ()
    local locale = "en-US"
    local bundle = fluent(locale)
    bundle:add_messages("foo = bar")
    assert.same("bar", bundle:format("foo"))
  end)

end)
