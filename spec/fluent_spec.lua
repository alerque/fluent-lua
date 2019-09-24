-- Internal modules
local FluentBundle = require("fluent")

describe('fluent.bundle', function ()

  it('should instantiate without any locale', function ()
    local und = FluentBundle()
    assert.is_true(und:is_a(FluentBundle))
  end)

  it('should instantiate with a locale', function ()
    local locale = "en-US"
    local en = FluentBundle(locale)
    assert.is_true(en:is_a(FluentBundle))
    assert.same(locale, en.locale)
  end)

  it('should parse and format single simple messages', function ()
    local en = FluentBundle("en-US")
    en:add_messages("foo = bar")
    assert.same("bar", en:format("foo"))
  end)

  it('should parse and format multiple simple messages', function ()
    local en = FluentBundle("en-US")
    en:add_messages("foo = bar\nbar = baz")
    assert.same("bar", en:format("foo"))
    assert.same("baz", en:format("bar"))
  end)

  it('should keep locale instances separate', function ()
    local en = FluentBundle("en-US")
    local tr = FluentBundle("tr-TR")
    assert.not_same(en, tr)
    en:add_messages("hi = hello")
    tr:add_messages("hi = merhaba")
    assert.same("hello", en:format("hi"))
    assert.same("merhaba", tr:format("hi"))
  end)

end)
