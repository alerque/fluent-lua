local fluent = require("fluent")

describe('fluent', function ()

  it('should instantiate with a locale', function ()
    local locale = "en-US"
    local en = fluent(locale)
    assert.truthy(en:is_a(fluent))
    assert.same(locale, en.locale)
  end)

  it('should parse single simple messages', function ()
    local en = fluent("en-US")
    en:add_messages("foo = bar")
    assert.same("bar", en.messages.foo)
  end)

  it('should parse multiple simple messages', function ()
    local en = fluent("en-US")
    en:add_messages("foo = bar\nbar = baz")
    assert.same("bar", en.messages.foo)
    assert.same("baz", en.messages.bar)
  end)

  it('should return formatted strings', function ()
    local en = fluent("en-US")
    en:add_messages("foo = bar")
    assert.same("bar", en:format("foo"))
  end)

  it('should keep locale instances separate', function ()
    local en = fluent("en-US")
    local tr = fluent("tr-TR")
    assert.not_same(en, tr)
  end)

  it('should return locale specific strings', function ()
    local en = fluent("en-US")
    local tr = fluent("tr-TR")
    en:add_messages("foo = bar")
    tr:add_messages("foo = baz")
    assert.same("bar", en:format("foo"))
    assert.same("baz", tr:format("foo"))
  end)

end)
