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

describe('upstream fixture', function ()
  local syntax = FluentSyntax()

  local fixtures_dir = lfs.currentdir() .. "/spec/fixtures/"
  for object in lfs.dir(fixtures_dir) do
    local fname = fixtures_dir .. object
    if fname:match(".ftl$") then
      describe(object, function ()
        local ftl = filetostring(fname)
        local jsonref = filetostring(fname:gsub(".ftl$", ".json"))
        local reference = json.decode(jsonref)

        local ast

        it('should have a reference', function()
          assert.equal("table", type(reference))
        end)

        it('should parse without blowing up', function ()
          assert.no.error(function () ast = syntax:parse(ftl) end)
        end)

        it('should have a Reference as the AST root', function ()
          assert.equal("Resource", ast.type)
        end)

        it('should matach the referece result', function ()
          assert.same(reference, ast)
        end)

      end)
    end
  end

end)
