-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")

local node_types = {}
local node_to_type

local FluentNode = class({
    discardable = false,
    appendable = false,
    resource = {},

    _init = function (self, node, resource)
      self.resource = resource
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
      tablex.foreachi(node, function (n) self:insert(node_to_type(n, resource)) end)
    end,

    insert = function (self, node)
      if type(node) ~= "table" then return nil end
      if not self:modify(node) and not self:attach(node) then
        if self.elements and #self.elements >= 1 then
          if not self.elements[#self.elements]:append(node) then
            table.insert(self.elements, node)
          end
        else
          if not self.elements then self.elements = {} end
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
      return node and type(node.__add) == "function" and node + self
    end,

    modify = function (self, node)
      return node and type(node.__mod) == "function" and node % self
    end,

    attach = function (self, node)
      return node and type(node.__mul) == "function" and node * self
    end,

    __call = function (self, ...)
      return self:format(...)
    end,

    __tostring = function (self)
      return self:format({})
    end,

    __concat = function (a, b)
      return tostring(a) .. tostring(b)
    end

  })

node_types.blank_block = class({
    discardable = true,
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
      local _, count = string.gsub(node[1], "\n", "")
      self.discardable = count == 0
    end
  })

node_types.Entry = function (node, resource)
  return node_to_type(node[1], resource)
end

node_types.Junk = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end
  })

node_types.Message = class({
    index = {},
    _base = FluentNode,
    _init = function (self, node, resource)
      self.attributes = {}
      self:super(node, resource)
      -- Penlight bug #307, should be — self:catch(self.get_attribute)
      self:catch(function (_, k) return self:get_attribute(k) end)
    end,
    get_attribute = function (self, attribute)
      return self.index[attribute] and self.attributes[self.index[attribute]] or nil
    end,
    format = function (self, parameters)
      return self.value:format(parameters, self.resource)
    end,
  })

node_types.Term = function (node, resource)
  return node_types.Message(node, resource)
end

node_types.Identifier = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end,
    __mod = function (self, node)
      node.id = self
      return node
    end
  })

node_types.Pattern = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self.elements = {}
      self:super(node, resource)
      self:dedent()
    end,
    dedent = function (self)
      local mindent = function (node)
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
      local strip = function (node, key, len)
        if type(node.value) == "string" then
          local value = string.gsub(node.value, "\r\n", "\n")
          if len >= 1 then
            value = string.gsub(value, strippref, "\n\n")
          end
          value = key == 1 and string.gsub(value, "^[\n ]+", "") or value
          value = key == #self.elements and string.gsub(value, "[\n ]+$", "") or value
          self.elements[key].value = value
        end
      end
      tablex.foreachi(self.elements, strip, striplen)
    end,
    __mul = function (self, node)
      if node:is_a(node_types.Message) or node:is_a(node_types.Attribute) or node:is_a(node_types.Variant) then
        node.value = self
        return node
      end
    end,
    format = function (self, parameters)
      local function evaluate (node) return node:format(parameters) end
      local value = table.concat(tablex.map(evaluate, self.elements))
      return value
    end
  })

node_types.TextElement = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node, resource)
      node.id = "TextElement"
      self:super(node, resource)
    end,
    __add = function (self, node)
      if self:is_a(node:is_a()) and self.appendable and node.appendable then
        node.value = (node.value or "") .. "\n" .. (self.value or "")
        return node
      end
    end,
    format = function (self)
      return self.value
    end
  })

node_types.Placeable = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node, resource)
      node.id = "Placeable"
      node.expression = tablex.reduce('+', tablex.map(node_to_type, node.expression, resource))
      self:super(node, resource)
    end,
    format = function (self, parameters)
      return self.expression:format(parameters)
    end
  })

node_types.PatternElement = function (node, resource)
  if node.value then
    return node_types.TextElement(node, resource)
  else
    return node_types.Placeable(node, resource)
  end
end

node_types.StringLiteral = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end,
    format = function (self)
      return self.value
    end
  })

node_types.NumberLiteral = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end,
    format = function (self)
      return self.value
    end
  })

node_types.VariableReference = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end,
    format = function (self, parameters)
      return parameters[self.id.name]
    end,
    __mod = function (self, node)
      if node:is_a(node_types.SelectExpression) then
        node.selector = self
        return node
      end
    end
  })

node_types.MessageReference = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end,
    format = function (self, parameters)
      return self.resource[self.id.name]:format(parameters)
    end
  })

node_types.TermReference = function (node, resource)
  return node_types.MessageReference(node, resource)
end

node_types.FunctionReference = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end
  })

node_types.SelectExpression = class({
    selector = {},
    variants = {},
    _base = FluentNode,
    _init = function (self, node, resource)
      node.id = "SelectExpression"
      self.selector = {}
      self.variants = {}
      self:super(node, resource)
    end,
    __add = function (self, node)
      if node:is_a(node_types.variant_list) then
        self.variants = node.elements
        return self
      end
    end
  })

node_types.InlineExpression = function(node, resource)
  return node_types.SelectExpression(node, resource)
end

node_types.variant_list = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end,
  })

node_types.Variant = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      node.id = "Variant"
      self:super(node, resource)
    end,
  })

node_types.VariantKey = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end,
    __mod = function (self, node)
      node.key = self.id
      return node
    end
  })

node_types.DefaultVariant = function (node, resource)
  node.default = true
  return node_types.Variant(node, resource)
end

node_types.CallArguments = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end
  })

node_types.NamedArgument = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end
  })

node_types.Comment = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end,
    __add = function (self, node)
      if node:is_a(self:is_a()) and node.appendable and self.appendable then
        node.content = (node.content or "") .. "\n" .. (self.content or "")
        return node
      end
    end,
    __mul = function (self, node)
      if node:is_a(node_types.Message) then
        node.comment = self
        return node
      end
    end
  })

node_types.GroupComment = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end,
    __add = node_types.Comment.__add
  })

node_types.ResourceComment = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end,
    __add = node_types.Comment.__add
  })

node_types.Attribute = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self:super(node, resource)
    end,
    __mul = function (self, node)
      if node:is_a(node_types.Message) then
        table.insert(node.attributes, self)
        node.index[self.id.name] = #node.attributes
        return node
      elseif self:is_a(node_types.Pattern) then
        node.value = self
        return node
      end
    end,
    format = function (self, parameters)
      return self.value:format(parameters)
    end
  })

node_types.CommentLine = function (node, resource)
  node.id = #node.sigil == 1 and "Comment"
          or #node.sigil == 2 and "GroupComment"
          or #node.sigil == 3 and "ResourceComment"
  return node_types[node.id](node, resource)
end

node_to_type = function (node, resource)
  if type(node) == "table" and type(node.id) == "string" then
    return node_types[node.id](node, resource)
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
        local node = node_to_type(leaf, self)
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
      -- Penlight bug #307, should be — self:catch(self.get_message)
      self:catch(function (_, k) return self:get_message(k) end)
    end,

    insert = function (self, node)
      table.insert(self.body, node)
      if node:is_a(node_types.Message) then
        self.index[node.id.name] = #self.body
      end
    end,

    get_message = function (self, identifier)
      local key = rawget(self.index, string.match(identifier, "^(%a[-_%a%d]+)"))
      if not key then return end
      local entry = rawget(self, "body")[key]
      if not entry then return end
      local attr = string.match(identifier, "%.([(%a[-_%a%d]+)$")
      return attr and entry.attributes[entry.index[attr]] or entry
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
