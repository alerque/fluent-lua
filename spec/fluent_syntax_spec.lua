local FluentSyntax = require("fluent.syntax")

describe('fluent.syntax', function ()

  it('should instantiate', function ()
    local syntax = FluentSyntax()
    assert.truthy(syntax:is_a(FluentSyntax))
  end)

end)
