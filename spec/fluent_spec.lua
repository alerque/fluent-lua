-- Internal modules
local FluentBundle = require("fluent")

describe('fluent.bundle', function ()

  it('should instantiate without any locale', function ()
    local und = FluentBundle()
    assert.is_true(und:is_a(FluentBundle))
  end)

  it('should instantiate with a locale', function ()
    local locale = "en"
    local en = FluentBundle(locale)
    assert.is_true(en:is_a(FluentBundle))
    assert.same(locale, en.locale)
  end)

  it('should parse and format single simple messages', function ()
    local en = FluentBundle("en")
    en:add_messages("foo = bar")
    assert.same("bar", en:format("foo"))
  end)

  it('should parse and format multiple simple messages', function ()
    local en = FluentBundle("en")
    en:add_messages("foo = bar\nbar = baz")
    assert.same("bar", en:format("foo"))
    assert.same("baz", en:format("bar"))
  end)

  it('should parse and format a table of strings', function ()
    local en = FluentBundle("en")
    en:add_messages({ "foo = bar", "bar = baz" })
    assert.same("bar", en:format("foo"))
    assert.same("baz", en:format("bar"))
  end)

  it('should parse and format literals', function ()
    local en = FluentBundle("en")
    en:add_messages('foo = bar {"baz"} quz {-3.14}')
    assert.same("bar baz quz -3.14", en:format("foo"))
  end)

  it('should parse and format a variable substitution', function ()
    local en = FluentBundle("en")
    en:add_messages('foo = bar { $baz }')
    assert.same("bar qux", en:format("foo", { baz = "qux" }))
  end)

  it('should parse and format a message reference', function ()
    local en = FluentBundle("en")
    en:add_messages('foo = bar\nbaz = a { foo }')
    assert.same("bar", en:format("foo"))
    assert.same("a bar", en:format("baz"))
  end)

  it('should parse and format a term reference', function ()
    local en = FluentBundle("en")
    en:add_messages('-foo = bar\nfoo = public\nbaz = a { -foo }')
    assert.same("public", en:format("foo"))
    assert.same("a bar", en:format("baz"))
  end)

  it('should parse and format an attribute', function ()
    local en = FluentBundle("en")
    en:add_messages([[
foo =
    { $ab ->
     *[a] bar
      [b] baz
      [c] qiz
    }
      ]])
    assert.same("bar", en:format("foo"))
    assert.same("bar", en:format("foo", { ab = "a" }))
    assert.same("baz", en:format("foo", { ab = "b" }))
    assert.same("qiz", en:format("foo", { ab = "c" }))
    assert.same("bar", en:format("foo", { ab = "d" }))
  end)

  it('should parse and format an attribute based on numbers', function ()
    local en = FluentBundle("en")
    en:add_messages([[
foo =
    { $num ->
     *[0] no bar
      [one] one bar
      [other] {$num} bars
    }
      ]])
    assert.same("no bar", en:format("foo"))
    assert.same("one bar", en:format("foo", { num = 1 }))
    assert.same("2 bars", en:format("foo", { num = 2 }))
    assert.same("37 bars", en:format("foo", { num = 37 }))
  end)

  describe('messages', function ()
    local en

    before_each(function ()
      en = FluentBundle("en")
      en:add_messages("hi = Hello { $name }!\nfoo = bar\nbar = baz\n    .bax = qux")
    end)

    after_each(function ()
      en = nil
    end)

    it('can be accessed with getter', function ()
      assert.same("bar", en:get_message("foo"):format())
      assert.same("bar", tostring(en:get_message("foo")))
      assert.same("baz", en:get_message("bar"):format())
      assert.same("baz", tostring(en:get_message("bar")))
    end)

    it('can be accessed as properties', function ()
      assert.same("bar", en.foo:format())
      assert.same("bar", en["foo"]:format())
      assert.same("baz", en.bar:format())
      assert.same("baz", en["bar"]:format())
    end)

    it('attributes can be accessed as properties', function ()
      assert.same("qux", en["bar.bax"]())
      assert.same("qux", en.bar["bax"]())
      assert.same("qux", en.bar.bax())
    end)

    it('preserves messages when messages are added', function ()
      assert.same("baz", en:format("bar"))
      assert.error(function () return en:format("aa") end)
      en:add_messages("aa = bb")
      assert.same("baz", en:format("bar"))
      assert.same("bb", en:format("aa"))
    end)

    it('updates messages when messages are readded', function ()
      assert.same("bar", en:format("foo"))
      assert.same("baz", en:format("bar"))
      en:add_messages("bar = rebar")
      assert.same("bar", en:format("foo"))
      assert.same("rebar", en:format("bar"))
    end)

    it('preserves attributes when messages are added', function ()
      assert.same("baz", en:format("bar"))
      assert.same("qux", en:get_message("bar"):get_attribute("bax")())
      -- assert.same("qux", en["bar.bax"]())
      -- assert.same("qux", en.bar.bax())
      en:add_messages("aa = bb")
      -- assert.same("qux", en["bar.bax"]())
      -- assert.same("qux", en.bar:get_attribute("bax")())
      assert.same("baz", en:format("bar"))
      assert.same("qux", en:get_message("bar"):get_attribute("bax")())
      en:add_messages("bar = rebar")
      assert.same("rebar", en:format("bar"))
      assert.error(function() return en:get_message("bar"):get_attribute("bax")() end)
      -- assert.same("qux", en.bar.bax())
    end)

    it('can be called', function ()
      assert.same("bar", en.foo())
      assert.same("bar", en["foo"]())
      assert.same("baz", en.bar())
      assert.same("baz", en["bar"]())
    end)

    it('can be called with parameters', function ()
      assert.same("Hello World!", en.hi({name = "World"}))
      assert.same("Hello World!", en["hi"]({name = "World"}))
      assert.same("Hello World!", en["hi"]:format({name = "World"}))
    end)

    it('can be cast to strings', function ()
      assert.same("baz", tostring(en.bar))
      assert.same("bar", tostring(en["foo"]))
      assert.same("xbar", "x" .. en.foo)
      assert.same("xbaz", "x" .. en["bar"])
      assert.same("barx", en.foo .. "x")
      assert.same("bazx", en["bar"] .. "x")
    end)

  end)

  it('should keep locale instances separate', function ()
    local en = FluentBundle("en")
    local tr = FluentBundle("tr")
    assert.not_same(en, tr)
    en:add_messages("hi = hello")
    tr:add_messages("hi = merhaba")
    assert.same("hello", en:format("hi"))
    assert.same("merhaba", tr:format("hi"))
  end)

end)
