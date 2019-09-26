-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")

local node_types = {}
local node_to_type

local FluentNode = class({
    discardable = false,
    appendable = false,

    _init = function (self, node)
      for key, value in pairs(node) do
        if type(key) == "string" then
          if key == "id" then
            self.type = value
          elseif key == "value" then
            self[key] = string.gsub(value, "^\n+ +", "")
          elseif key ~= "pos" and key ~= "sigil" then
            self[key] = value
          end
        end
      end
      tablex.foreachi(node, function (n) self:insert(node_to_type(n)) end)
    end,

    insert = function (self, node)
      if type(node) ~= "table" then return nil end
      if node:is_a(node_types.Identifier) then
        self.id = node
      elseif node:is_a(node_types.Pattern) then
        self.value = node
      else
        if not self.elements then self.elements = {} end
        if #self.elements >= 1 then
          if not self.elements[#self.elements]:append(node) then
            table.insert(self.elements, node)
          end
        else
          table.insert(self.elements, node)
        end
      end
    end,

    dump_ast = function (self)
      local ast = { type = self.type }
      for k, v in pairs(self) do ast[k] = v end
      return ast
    end,

    append = function (self, node)
      return node and type(node.__add) == "function" and self + node
    end,

    attach = function (self, node)
      return node and type(node.__mul) == "function" and self * node
    end

  })

node_types.blank_block = class({
    discardable = true,
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
      local _, count = string.gsub(node[1], "\n", "")
      self.discardable = count == 0
    end
  })

node_types.Entry = function(node)
  return node_to_type(node[1])
end

node_types.Junk = class({
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end
  })

node_types.Message = class({
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
      self.attributes = {}
    end,
    format = function (self, parameters)
      return self.value:format(parameters)
    end,
  })

node_types.Term = function(node)
  return node_types.Message(node)
end

node_types.Identifier = class({
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end
  })

node_types.Pattern = class({
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
      self:dedent()
    end,
    dedent = function (self)
      local mindent = function(node)
        local indents = {}
        if type(node.value) == "string" then
          for indent in string.gmatch(node.value, "\n *%S") do
            table.insert(indents, #indent-2)
          end
        end
        return tablex.reduce(math.min, indents) or 0
      end
      local striplen = tablex.reduce(math.min, tablex.imap(mindent, self.elements)) or 0
      local i, strippref = 1, "\n"
      while i <= striplen do
        strippref = strippref .. " "
        i = i + 1
      end
      local strip = function(node, key, len)
        if type(node.value) == "string" then
          local value = string.gsub(node.value, "\r\n", "\n")
          if len >= 1 then
            value = string.gsub(value, strippref, "\n\n")
          end
          value = string.gsub(value, "^[\n ]+", "")
          value = string.gsub(value, "[\n ]+$", "")
          self.elements[key].value = value
        end
      end
      tablex.foreachi(self.elements, strip, striplen)
    end,
    format = function (self, parameters)
      local function evaluate (node) return node:format(parameters) end
      local value = table.concat(tablex.map(evaluate, self.elements), " ")
      return value, parameters
    end
  })

node_types.TextElement = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node)
      node.id = "TextElement"
      self:super(node)
    end,
    __add = function (self, node)
      if self:is_a(node:is_a()) and self.appendable and node.appendable then
        self.value = (self.value or "") .. "\n" .. (node.value or "")
        return self
      end
    end,
    format = function (self)
      return self.value
    end
  })

node_types.Placeable = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node)
      node.id = "Placeable"
      self:super(node)
      if node.expression then
        self.expression = node_to_type(node.expression[1])
      end
    end,
    format = function (self)
      return self.expression.value
    end
  })

node_types.PatternElement = function (node)
  if node.value then
    return node_types.TextElement(node)
  else
    return node_types.Placeable(node)
  end
end

node_types.StringLiteral = class({
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end,
    format = function (self)
      return self.value
    end
  })

node_types.NumberLiteral = class({
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end,
    format = function (self)
      return self.value
    end
  })

node_types.VariableReference = class({
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end,
    format = function (self)
      return self.value
    end
  })

node_types.Comment = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end,
    __add = function (self, node)
      if self:is_a(node:is_a()) and self.appendable and node.appendable then
        self.content = (self.content or "") .. "\n" .. (node.content or "")
        return self
      end
    end,
    __mul = function (self, node)
      if self:is_a(node_types.Message) then
        self.comment = node
        return self
      elseif node:is_a(node_types.Message) then
        node.comment = self
        return node
      end
    end
  })

node_types.GroupComment = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end,
    __add = node_types.Comment.__add
  })

node_types.ResourceComment = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end,
    __add = node_types.Comment.__add
  })

node_types.Attribute = class({
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end
  })

node_types.CommentLine = function(node)
  node.id = #node.sigil == 1 and "Comment"
          or #node.sigil == 2 and "GroupComment"
          or #node.sigil == 3 and "ResourceComment"
  return node_types[node.id](node)
end

node_to_type = function (node)
  if type(node) == "table" and type(node.id) == "string" then
    return node_types[node.id](node)
  end
end

local FluentResource = class({
    type = "Resource",
    index = {},

    _init = function (self, ast)
      self.body = {}
      local _stash = nil
      local flush = function ()
        if _stash then
          self:insert(_stash)
          _stash = nil
        end
        return #self.body
      end
      local stash = function (node)
        if not _stash then
          _stash = node
        elseif not _stash:append(node) then
          flush()
          _stash = node
        end
      end
      for _, leaf in ipairs(ast) do
        local node = node_to_type(leaf)
        if node:is_a(node_types.blank_block) then
          if not node.discardable then
            flush()
          end
        elseif node:attach(_stash) then
          _stash = nil
          stash(node)
        else
          stash(node)
        end
      end
      flush()
      -- self:catch(function (self, identifier) return self:get_message(identifier) end)
    end,

    insert = function (self, node)
      table.insert(self.body, node)
      if node:is_a(node_types.Message) then
        self.index[node.id.name] = #self.body
      end
    end,

    get_message = function (self, identifier)
      return self.index[identifier] and self.body[self.index[identifier]]
    end,

    dump_ast = function (self)
      local ast =  { type = "Resource", body = {} }
      for _, v in ipairs(self.body) do table.insert(ast.body, v:dump_ast()) end
      return ast
    end,

    __add = function (self, resource)
      if not self:is_a(resource:is_a()) then error("Cannot merge unlike types") end
      for _, node in ipairs(resource.body) do
        self:insert(node)
      end
      return self
    end

  })

return FluentResource
