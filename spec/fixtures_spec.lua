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

describe('upstream reference fixture', function ()
  local syntax = FluentSyntax()

  local fixtures_dir = lfs.currentdir() .. "/spec/fixtures/"
  for object in lfs.dir(fixtures_dir) do
    local fname = fixtures_dir .. object
    if fname:match(".ftl$") then
      describe(object, function ()
        local ftl = filetostring(fname)
        local jsonref = filetostring(fname:gsub(".ftl$", ".json"))
        local reference = json.decode(jsonref)

        local resource

        it('test should have a reference', function()
          assert.equal("table", type(reference))
        end)

        it('should parse without blowing up', function ()
          assert.no.error(function () resource = syntax:parsestring(ftl) end)
        end)

        it('should have a Resource as the AST root', function ()
          assert.equal("Resource", resource.type)
        end)

        it('should match the referece result', function ()
          assert.same(reference, resource:dump_ast())
        end)

      end)
    end
  end

end)

describe('upstream structure fixture', function ()
  local syntax = FluentSyntax()

  local fixtures_dir = lfs.currentdir() .. "/spec/structure/"
  for object in lfs.dir(fixtures_dir) do
    local fname = fixtures_dir .. object
    if fname:match(".ftl$") then
      describe(object, function ()
        local ftl = filetostring(fname)
        local jsonref = filetostring(fname:gsub(".ftl$", ".json"))
        local reference = json.decode(jsonref)

        local resource

        it('should have a reference', function()
          assert.equal("table", type(reference))
        end)

        it('should parsestring without blowing up', function ()
          assert.no.error(function () resource = syntax:parsestring(ftl) end)
        end)

        it('should have a Reference as the AST root', function ()
          assert.equal("Resource", resource.type)
        end)

        it('should match the referece result', function ()
          assert.same(reference, resource:dump_ast())
        end)

      end)
    end
  end

end)
