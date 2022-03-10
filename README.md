# Fluent Lua¹

[![Luacheck](https://github.com/alerque/fluent-lua/workflows/Luacheck/badge.svg)](https://github.com/alerque/fluent-lua/actions)
[![Busted](https://github.com/alerque/fluent-lua/workflows/Busted/badge.svg)](https://github.com/alerque/fluent-lua/actions)
[![Coverage Status](https://coveralls.io/repos/github/alerque/fluent-lua/badge.svg?branch=master)](https://coveralls.io/github/alerque/fluent-lua?branch=master)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/alerque/fluent-lua)](https://github.com/alerque/fluent-lua/releases)
[![LuaRocks](https://img.shields.io/luarocks/v/alerque/fluent)](https://luarocks.org/modules/alerque/fluent)
[![Join the chat at https://gitter.im/fluent-lua/community](https://badges.gitter.im/fluent-lua/community.svg)](https://gitter.im/fluent-lua/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A Lua implementation of [Project Fluent][projectfluent], a localization paradigm designed to unleash the entire expressive power of natural language translations. Fluent is a family of localization specifications, implementations and good practices developed by Mozilla who extracted parts of their 'l20n' solution (used in Firefox and other apps) into a re-usable specification. For more information also see the [Fluent Syntax Guide][syntaxguide], the [Discourse channel][discourse], [documentation wiki][wiki], and [playground][play].

Other implementations already exist in [Rust][fluent-rs], [Javascript][fluent.js], [Python][python-fluent], [c#][fluent.net], [elm][elm-fluent], and [perl][perl-fluent]. See also [other implementations][others].

¹ <sub>Fluent the localization paradigm, not to be confused with Fluent the [API interface concept][fluentinterface]!</sub>

## Status

It is possible to use this for simple string localization with basic parameter substitution but it is not feature complete nor is the API stable (see [Lua alternatives](#alternatives)). If you have ideas about how the Lua API should work or wish to contribute, please join the project chat and/or open [issues](https://github.com/alerque/fluent-lua/issues) for points of discussion.

- [x] Parse FTL input strings
- [x] Format Basic messages
- [x] Format String and Number literals
- [x] Substitute VariableReferences
- [x] Handle Attributes
- [x] Handle Variants using SelectExpressions
- [x] Handle TermsReferences
- [x] Handle MessageReferences
- [ ] Setup Locale fallbacks in Bundle
- [ ] Localize number formatting
- [ ] Functions

## Changelog

Please see [CHANGELOG.md](./CHANGELOG.md).

## Usage

Lua code `demo.lua`:

```lua
-- Import and start a new instance
local FluentBundle = require("fluent")
local bundle = FluentBundle()

-- Load some messages (can be a string or table of strings)
bundle:add_messages([[
hello = Hello { $name }!
foo = bar
    .attr = baz
]])

-- Access methods like other Fluent implementations
print(bundle:format("foo"))
print(bundle:format("foo.attr"))
print(bundle:format("hello", { name = "World" }))

-- Alternate idomatic Lua access methods
print(bundle["foo"]) -- access property, implicit cast to string, cannot pass parammeters
print("Attr: " .. bundle.foo.attr) -- access attributes as property, allow contatenation
print(bundle.hello({ name = "World" })) -- access as property is callable, parameters passed to format()
```

Output of `lua demo.lua`:

```txt
bar
baz
Hello World!
bar
Attr: baz
Hello World!
```

## Alternative(s)

Fluent-lua is usage for many basic use-cases but it is not 100% feature complete. If you need something more mature (and don’t have the energy to contribute here), have a look at the `i18n.lua` project ([Github](https://github.com/kikito/i18n.lua) / [LuaRocks](https://luarocks.org/modules/kikito/i18n)). It implements many of the same features this project will, just without the interoperability with other Fluent based tools. The Lua API it provides is quite nice, but your localization data needs to be provided in Lua tables instead of FTL files. While Fluent has quite a few more tricks up its sleeve the *i18n* module already has working interpolation, pluralization, locale fallbacks, and more. And it works now, today.

Another even simpler solution is the Lua `say` module ([Github](https://github.com/Olivine-Labs/say) / [LuaRocks](https://luarocks.org/modules/olivine-labs/say)) from the makers of Busted. This is much closer to a flat one-to-one key value map, but with namespacing in such a way that it is useful for localization.

## Design Goals

 This project's end goal is to provide an idiomatic Lua API implementing the [Fluent spec][fluent] that is fully compatible with other FTL based tooling. This will allow Lua projects to easily implement localized interfaces with natural sounding translations and take advantage of tools such as [Pontoon][pontoon].

  [discourse]: https://discourse.mozilla.org/c/fluent
  [elm-fluent]: https://github.com/elm-fluent/elm-fluent
  [fluent-rs]: https://github.com/projectfluent/fluent-rs
  [fluent.js]: https://github.com/projectfluent/fluent.js
  [fluent.net]: https://github.com/blushingpenguin/Fluent.Net
  [fluent]: https://github.com/projectfluent/fluent
  [fluentinterface]: https://en.wikipedia.org/wiki/Fluent_interface
  [others]: https://github.com/projectfluent/fluent#other-implementations
  [perl-fluent]: https://github.com/alabamenhu/Fluent
  [play]: https://projectfluent.org/play/
  [pontoon]: https://github.com/mozilla/pontoon
  [projectfluent]: https://projectfluent.org
  [python-fluent]: https://github.com/projectfluent/python-fluent
  [syntaxguide]: http://projectfluent.org/fluent/guide
  [wiki]: https://github.com/projectfluent/fluent/wiki
