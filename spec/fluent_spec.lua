local fluent = require("fluent")

describe('fluent', function ()

  it('should instantiate', function ()
    assert.is.truthy(type(fluent) == "table")
  end)

end)
