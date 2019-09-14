# Fluent Lua¹

[![Luacheck](https://github.com/alerque/fluent-lua/workflows/Luacheck/badge.svg)](https://github.com/alerque/fluent-lua/actions)
[![Busted](https://github.com/alerque/fluent-lua/workflows/Busted/badge.svg)](https://github.com/alerque/fluent-lua/actions)
[![GitHub tag (latest SemVer)](https://img.shields.io/github/v/tag/alerque/fluent-lua)](https://github.com/alerque/fluent-lua/releases)
[![LuaRocks](https://img.shields.io/luarocks/v/alerque/fluent)](https://luarocks.org/modules/alerque/fluent)
[![Join the chat at https://gitter.im/fluent-lua/community](https://badges.gitter.im/fluent-lua/community.svg)](https://gitter.im/fluent-lua/community?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A Lua implementation of [Project Fluent][projectfluent], a localization paradigm designed to unleash the entire expressive power of natural language translations. Fluent is a family of localization specifications, implementations and good practices developed by Mozilla who extracted parts of their 'l20n' solution (used in Firefox and other apps) into a re-usable specification. For more information also see the [Fluent Syntax Guide][syntaxguide], the [Discourse channel][discourse], [documentation wiki][wiki], and [playground][play].

Other implementations already exist in [Rust][fluent-rs], [Javascript][fluent.js], [Python][python-fluent], [c#][fluent.net], [elm][elm-fluent], and [perl][perl-fluent]. See also [other implementations][others].

¹ <sub>Fluent the localization paradigm, not to be confused with Fluent the [API interface concept][fluentinterface]!</sub>

## Status

As of yet this does nothing *usable* (see [lua alternatives](#alternatives)). I'm actively soliciting feedback on how the API should look and work in Lua from several projects that might use it. If this is of interest to you please join the project chat and/or open [issues](https://github.com/alerque/fluent-lua/issues) for points of discussion.

**Update 2019-09-14**: I've completed a PEG grammar based parser for the entire 1.0 Fluent file format spec. All the pieces are there, but it's only partially tested. It at least parses a few basic types of entries. The AST it returns is straight out of *luaebnf* and probably needs massaging to match the reference ones (via capture groups?), then it needs testing against the upstream fixtures.

## Alternative(s)

If you need something that works in Lua *now*, have a look at the already mature `i18n.lua` project ([Github](https://github.com/kikito/i18n.lua) / [LuaRocks](https://luarocks.org/modules/kikito/i18n)). It implements many of the same features this project will, just without the interoperability with other Fluent based tools. The Lua API it provides is quite nice, but your localization data needs to be provided in Lua tables instead of FTL files. While Fluent has quite a few more tricks up its sleeve the *i18n* module already has working interpolation, pluralization, locale fallbacks, and more.  And it works now, today.

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
