rockspec_format = "1.0"
package = "fluent"
version = "0.1.3-0"

source = {
   url = "git+https://github.com/alerque/fluent-lua.git",
   dir = "fluent-lua",
   tag = "v0.1.3"
}

description = {
   summary = "Lua implementation of Project Fluent",
   detailed = [[A Lua port of Project Fluent, a localization paradigm designed to unleash
      the entire expressive power of natural language translations.]],
   license = "MIT",
   homepage = "https://github.com/alerque/fluent-lua",
}

dependencies = {
   "lua >= 5.1",
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
