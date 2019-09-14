-- External dependencies
local lfs = require("lfs")
local json = require("dkjson")

-- Internal modules
local FluentSyntax = require("fluent.syntax")

local function filetostring (fname)
  local f = assert(io.open(fname, "rb"))
  local content = f:read("*all")
  f:close()
  return content
end

describe('upstream fixtures', function ()
  local syntax = FluentSyntax()

  local fixtures_dir = lfs.currentdir() .. "/spec/fixtures/"
  for object in lfs.dir(fixtures_dir) do
    local fname = fixtures_dir .. object
    if fname:match(".ftl$") then
      describe(object, function ()
        local ftl = filetostring(fname)
        local jsonref = filetostring(fname:gsub(".ftl$", ".json"))
        local reference = json.decode(jsonref)

        it('should parse without blowing up', function ()
          assert.no.error(function () syntax:parse(ftl) end)
        end)

      end)
    end
  end

end)
