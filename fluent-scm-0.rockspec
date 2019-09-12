package = "fluent"
version = "scm-0"

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
   "lua"
}

build = {
   type = "builtin",
   modules = {
      ["fluent"] = "fluent/init.lua"
   }
}
