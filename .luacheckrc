std = "max"
include_files = {
  "**/*.lua",
  "*.rockspec",
  ".busted",
  ".luacheckrc"
}
exclude_files = {
  ".lua",
  ".luarocks",
  ".install"
}
files["spec"] = {
	std = "+busted"
}
max_line_length = false
