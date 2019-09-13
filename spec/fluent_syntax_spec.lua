local syntax = require("fluent.syntax")

describe('fluent.syntax', function ()

  it('should instantiate', function ()
    local s = syntax()
    assert.truthy(s:is_a(syntax))
  end)

end)
