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

    it('should handle blank blocks', function ()
      assert.equals(0, #syntax:parse(" "))
      assert.equals(0, #syntax:parse(" \n  \n"))
    end)

    it('should handle a simple entry', function ()
      assert.equals("Entry", syntax:parse("foo = bar")[1].id)
      assert.equals("Entry", syntax:parse("baz = qiz")[1].id)
    end)

    it('should handle simple comments', function ()
      assert.same("CommentLine", syntax:parse("# foo")[1][1].id)
      assert.same("CommentLine", syntax:parse("## foo")[1][1].id)
      assert.same("CommentLine", syntax:parse("### foo")[1][1].id)
    end)

    it('should handle junk', function ()
      assert.equals("Junk", syntax:parse("foo{")[1].id)
      assert.equals("Junk", syntax:parse("ą=b")[1].id)
      assert.equals("Junk", syntax:parse("!")[1].id)
      assert.equals("Junk", syntax:parse("#foo")[1].id)
    end)

  end)

end)
