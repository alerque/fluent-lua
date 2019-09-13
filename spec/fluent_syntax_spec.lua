local FluentSyntax = require("fluent.syntax")

describe('fluent.syntax', function ()
  local syntax = FluentSyntax()

  it('should instantiate', function ()
    assert.truthy(syntax:is_a(FluentSyntax))
  end)

  describe('parser', function ()

    it('should be called as a method', function ()
      assert.error(function () syntax.parse() end)
      assert.error(function () syntax.parse("") end)
    end)

    it('should require a string', function ()
      assert.error(function () syntax:parse() end)
      assert.error(function () syntax:parse(false) end)
      assert.error(function () syntax:parse(1) end)
      assert.error(function () syntax:parse({}) end)
    end)

    it('should return an AST', function ()
      local ast = syntax:parse("")
      assert.same("Resource", ast.id)
    end)

  end)

end)
