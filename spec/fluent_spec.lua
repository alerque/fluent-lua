-- Internal modules
local FluentBundle = require("fluent")

describe('fluent.bundle', function ()

  it('should instantiate without any locale', function ()
    local bundle = FluentBundle()
    assert.is_true(bundle:is_a(FluentBundle))
    assert.same("und", bundle.locale)
  end)

  it('should instantiate with a locale', function ()
    local locale = "en"
    local bundle = FluentBundle(locale)
    assert.is_true(bundle:is_a(FluentBundle))
    assert.same(locale, bundle.locale)
  end)

  it('should parse and format single simple messages', function ()
    local bundle = FluentBundle("en")
    bundle:add_messages("foo = bar")
    assert.same("bar", bundle:format("foo"))
  end)

  it('should parse and format multiple simple messages', function ()
    local bundle = FluentBundle("en")
    bundle:add_messages("foo = bar\nbar = baz")
    assert.same("bar", bundle:format("foo"))
    assert.same("baz", bundle:format("bar"))
  end)

  it('should parse and format a table of strings', function ()
    local bundle = FluentBundle("en")
    bundle:add_messages({ "foo = bar", "bar = baz" })
    assert.same("bar", bundle:format("foo"))
    assert.same("baz", bundle:format("bar"))
  end)

  it('should parse and format literals', function ()
    local bundle = FluentBundle("en")
    bundle:add_messages('foo = bar {"baz"} quz {-3.14}')
    assert.same("bar baz quz -3.14", bundle:format("foo"))
  end)

  it('should parse and format a variable substitution', function ()
    local bundle = FluentBundle("en")
    bundle:add_messages('foo = bar { $baz }')
    assert.same("bar qux", bundle:format("foo", { baz = "qux" }))
  end)

  it('should parse and format a message reference', function ()
    local bundle = FluentBundle("en")
    bundle:add_messages('foo = bar\nbaz = a { foo }')
    assert.same("bar", bundle:format("foo"))
    assert.same("a bar", bundle:format("baz"))
  end)

  it('should parse and format a term reference', function ()
    local bundle = FluentBundle("en")
    bundle:add_messages('-foo = bar\nfoo = public\nbaz = a { -foo }')
    assert.same("public", bundle:format("foo"))
    assert.same("a bar", bundle:format("baz"))
  end)

  it('should parse and format an attribute', function ()
    local bundle = FluentBundle("en")
    bundle:add_messages([[
foo =
    { $ab ->
     *[a] bar
      [b] baz
      [c] qiz
    }
      ]])
    assert.same("bar", bundle:format("foo"))
    assert.same("bar", bundle:format("foo", { ab = "a" }))
    assert.same("baz", bundle:format("foo", { ab = "b" }))
    assert.same("qiz", bundle:format("foo", { ab = "c" }))
    assert.same("bar", bundle:format("foo", { ab = "d" }))
  end)

  it('should parse and format an attribute based on numbers', function ()
    local bundle = FluentBundle("en")
    bundle:add_messages([[
foo =
    { $num ->
     *[0] no bar
      [one] one bar
      [other] {$num} bars
    }
      ]])
    assert.same("no bar", bundle:format("foo"))
    assert.same("one bar", bundle:format("foo", { num = 1 }))
    assert.same("2 bars", bundle:format("foo", { num = 2 }))
    assert.same("37 bars", bundle:format("foo", { num = 37 }))
  end)

  describe('messages', function ()
    local bundle, en

    before_each(function ()
      bundle = FluentBundle("en")
      en = bundle:get_resource()
      bundle:add_messages("hi = Hello { $name }!\nfoo = bar\nbar = baz\n    .bax = qux")
    end)

    after_each(function ()
      bundle, en = nil, nil
    end)

    it('can be accessed with getter', function ()
      assert.same("bar", bundle:get_message("foo"):format())
      assert.same("bar", tostring(bundle:get_message("foo")))
      assert.same("baz", bundle:get_message("bar"):format())
      assert.same("baz", tostring(bundle:get_message("bar")))
    end)

    it('can be accessed as properties', function ()
      assert.same("bar", bundle.foo:format())
      assert.same("bar", en.foo:format())
      assert.same("bar", bundle["foo"]:format())
      assert.same("baz", bundle.bar:format())
      assert.same("baz", en.bar:format())
      assert.same("baz", bundle["bar"]:format())
      assert.error(function () return bundle.apple:format() end)
      assert.error(function () return en.apple:format() end)
      assert.error(function () return bundle["apple"]:format() end)
    end)

    pending('attributes can be accessed as properties', function ()
      assert.same("qux", bundle["bar.bax"]())
      assert.same("qux", bundle.bar["bax"]())
      assert.same("qux", bundle.bar.bax())
    end)

    it('preserves messages when messages are added', function ()
      assert.same("baz", bundle:format("bar"))
      assert.error(function () return bundle:format("aa") end)
      bundle:add_messages("aa = bb")
      assert.same("baz", bundle:format("bar"))
      assert.same("bb", bundle:format("aa"))
    end)

    it('updates messages when messages are readded', function ()
      assert.same("bar", bundle.foo())
      assert.same("bar", bundle:format("foo"))
      assert.same("baz", bundle.bar())
      assert.same("baz", bundle:format("bar"))
      bundle:add_messages("bar = rebar")
      assert.same("bar", bundle.foo())
      assert.same("bar", bundle:format("foo"))
      assert.same("rebar", bundle.bar())
      assert.same("rebar", bundle:format("bar"))
    end)

    it('preserves attributes when messages are added', function ()
      assert.same("baz", bundle.bar())
      assert.same("baz", en.bar())
      assert.same("baz", bundle:format("bar"))
      assert.same("qux", bundle:get_message("bar"):get_attribute("bax")())
      -- assert.same("qux", bundle["bar.bax"]())
      -- assert.same("qux", bundle.bar.bax())
      bundle:add_messages("aa = bb")
      -- assert.same("qux", bundle["bar.bax"]())
      -- assert.same("qux", bundle.bar:get_attribute("bax")())
      assert.same("baz", bundle.bar())
      -- TODO fix property accessor on resource
      -- assert.same("baz", en.bar())
      assert.same("baz", bundle:format("bar"))
      assert.same("qux", bundle:get_message("bar"):get_attribute("bax")())
      bundle:add_messages("bar = rebar")
      assert.same("rebar", bundle.bar())
      -- TODO fix property accessor on resource
      -- assert.same("rebar", en.bar())
      assert.same("rebar", bundle:format("bar"))
      assert.error(function() return bundle:get_message("bar"):get_attribute("bax")() end)
      -- assert.same("qux", bundle.bar.bax())
    end)

    it('can be called', function ()
      assert.same("bar", bundle.foo())
      assert.same("bar", en.foo())
      assert.same("bar", bundle["foo"]())
      assert.same("bar", en["foo"]())
      assert.same("baz", bundle.bar())
      assert.same("baz", en.bar())
      assert.same("baz", bundle["bar"]())
      assert.same("baz", en["bar"]())
    end)

    it('can be called with parameters', function ()
      assert.same("Hello World!", bundle.hi({name = "World"}))
      assert.same("Hello World!", en.hi({name = "World"}))
      assert.same("Hello World!", bundle["hi"]({name = "World"}))
      assert.same("Hello World!", en["hi"]({name = "World"}))
      assert.same("Hello World!", bundle["hi"]:format({name = "World"}))
      assert.same("Hello World!", en["hi"]:format({name = "World"}))
    end)

    it('can be cast to strings', function ()
      assert.same("baz", tostring(bundle.bar))
      assert.same("baz", tostring(en.bar))
      assert.same("bar", tostring(bundle["foo"]))
      assert.same("bar", tostring(en["foo"]))
      assert.same("xbar", "x" .. bundle.foo)
      assert.same("xbar", "x" .. en.foo)
      assert.same("xbaz", "x" .. bundle["bar"])
      assert.same("xbaz", "x" .. en["bar"])
      assert.same("barx", bundle.foo .. "x")
      assert.same("barx", en.foo .. "x")
      assert.same("bazx", bundle["bar"] .. "x")
      assert.same("bazx", en["bar"] .. "x")
    end)

  end)

  it('should keep bundle instances separate', function ()
    local bundle1 = FluentBundle("en")
    local bundle2 = FluentBundle("tr")
    assert.not_same(bundle1, bundle2)
    bundle1:add_messages("hi = hello")
    bundle2:add_messages("hi = merhaba")
    assert.same("hello", bundle1:format("hi"))
    assert.same("merhaba", bundle2:format("hi"))
  end)

  it('should not clobber itself when adding locales', function ()
    local bundle = FluentBundle("en")
    -- confirm we have a clean instance, not the previous test
    assert.error(function () return bundle:format("hi") end)
    bundle:add_messages("hi = hello")
    assert.same("hello", bundle:format("hi"))
    bundle:set_locale("tr")
    bundle:add_messages("hi = merhaba")
    assert.same("merhaba", bundle:format("hi"))
    bundle:set_locale("en")
    bundle:add_messages("hi = hello")
    local en = bundle:get_resource("en")
    local tr = bundle:get_resource("tr")
    assert.same("merhaba", tr:format("hi"))
    assert.same("hello", en:format("hi"))
  end)

end)
