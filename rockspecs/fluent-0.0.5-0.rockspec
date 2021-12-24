rockspec_format = "3.0"
package = "fluent"
version = "0.0.5-0"

source = {
   url = "git://github.com/alerque/fluent-lua.git",
   tag = "v0.0.5"
}

description = {
   summary = "Lua implementation of Project Fluent",
   detailed = [[
      A Lua port of Project Fluent, a localization paradigm designed to unleash
	  the entire expressive power of natural language translations.
   ]],
   license = "MIT",
   homepage = "https://github.com/alerque/fluent-lua",
   issues_url = "https://github.com/alerque/fluent-lua/issues",
   maintainer = "Caleb Maclennan <caleb@alerque.com>",
   labels = { "i18n" }
}

dependencies = {
   "lua",
   "cldr",
   "luaepnf",
   "penlight"
}

build = {
   type = "builtin",
   modules = {
      ["fluent.init"] = "fluent/init.lua",
      ["fluent.messages"] = "fluent/messages.lua",
      ["fluent.parser"] = "fluent/parser.lua",
      ["fluent.resource"] = "fluent/resource.lua",
      ["fluent.syntax"] = "fluent/syntax.lua"
   }
}
