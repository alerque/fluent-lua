package = "fluent"
version = "0.0.2-0"

source = {
   url = "git://github.com/alerque/fluent-lua",
}

description = {
   summary = "Lua implementation of Project Fluent.",
   detailed = [[
      This is a lua port of the Fluent, A localization paradigm designed to
	  unleash the entire expressive power of natural language translations.
   ]],
   homepage = "https://github.com/alerque/fluent-lua",
   license = "MIT"
}

dependencies = {
   "lua",
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
