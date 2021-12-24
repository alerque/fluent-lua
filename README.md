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

### 0.0.5

Cut a safe-haven release for anybody (including myself) using this in production before I move on.
Looking at Git history it looks like refinements include improved PEG grammars, saner namespacing for easier project integration, better use of Penlight classing, and more advanced handling of terms.
Dependencies now include cldr-lua, and tests now use CLDR compatible locales.
Lua 5.4 support was also officially added.

### 0.0.4

Add support for attributes plus access to messages using idiomatic Lua (table properties).

### 0.0.3

Added support for more types including format support for TextElement, StringLiteral, NumberLiteral, and VariableReference. Variable sutstitions can be done by passing a parameters table to `format()`. Internally manipulating nodes in the API is now easier with meta methods. For example merge comments with `Comment + Comment`, attach childred with `Message * Comment`, etc.

### 0.0.2

Massaged the AST returned by the PEG grammar so that about 1/3 of the possible types look like the reference Fluent spec. A basic Lua API is starting to take shape, modeled most closely to the Python implementation. It is possible to load and parse almost any FTL file, and possible to format any messages that are plain strings (no parameters, attributes, functions, or other jazz yet). Note there is no locale handling yet so it's only usable with separate instances per locale. Also `add_messages()` likely only works once, so cram your whole FTL resource in there for now.

### 0.0.1

Completed a PEG grammar based parser for the entire 1.0 Fluent file format spec. All the pieces are there, but it's only partially tested. It at least parses a few basic types of entries. The AST it returns is straight out of *luaebnf* and probably needs massaging to match the reference ones (via capture groups?), then it needs testing against the upstream fixtures.

### 0.0.0

Initialized project with some boiler plate Lua aparatus.

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

If you need something that works in Lua *now*, have a look at the already mature `i18n.lua` project ([Github](https://github.com/kikito/i18n.lua) / [LuaRocks](https://luarocks.org/modules/kikito/i18n)). It implements many of the same features this project will, just without the interoperability with other Fluent based tools. The Lua API it provides is quite nice, but your localization data needs to be provided in Lua tables instead of FTL files. While Fluent has quite a few more tricks up its sleeve the *i18n* module already has working interpolation, pluralization, locale fallbacks, and more.  And it works now, today.

Another even simpler solution is the Lua `say` module ([Github](https://github.com/Olivine-Labs/say) / [LuaRocks](https://luarocks.org/modules/olivine-labs/say)) from the makers of Busted. This is much closer to a flat one-to-one key value map, but with namespacing is such a way that it is useful for localization.

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
