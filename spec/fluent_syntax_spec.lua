local FluentSyntax = require("fluent.syntax")

describe('fluent.syntax', function ()
  local syntax = FluentSyntax()

  it('should instantiate', function ()
    assert.truthy(syntax:is_a(FluentSyntax))
  end)

  describe('parser', function ()

    it('should return an AST', function ()
      local ast = syntax:parse("-")
      assert.same("Resource", ast.id)
    end)

  end)

end)
