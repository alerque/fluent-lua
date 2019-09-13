local FluentSyntax = require("fluent.syntax")

describe('fluent.syntax', function ()
  local syntax = FluentSyntax()

  it('should instantiate', function ()
    assert.truthy(syntax:is_a(FluentSyntax))
  end)

  describe('parse', function ()

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

    it('should return an empty AST on no input', function ()
      local ast = syntax:parse("")
      assert.equals("Resource", ast.id)
      assert.equals(0, #ast)
    end)

    it('should handle a simple entry', function ()
      local ast = syntax:parse("foo = bar")
      assert.equals("Entry", ast[1].id)
    end)

    it('should handle a blank block', function ()
      local ast = syntax:parse(" ")
      assert.equals("blank_block", ast[1].id)
    end)

    -- it('should handle a simple comment', function ()
    --   local ast = syntax:parse("# foo")
    --   assert.same("Comment", ast[1].id)
    -- end)

    it('should handle junk', function ()
      local ast = syntax:parse("!")
      assert.equals("Junk", ast[1].id)
    end)

  end)

end)
