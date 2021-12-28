-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")

local FTL = {}
local node_to_type

local FluentNode = class({

    _init = function (self, node, resource)
      getmetatable(self)._resource = resource
      for key, value in pairs(node) do
        if type(key) == "string" then
          if key == "id" then
            self.type = value
          elseif key == "value" then
            self[key] = string.gsub(string.gsub(value, "\r\n?","\n"), "^\n+ +", "")
          elseif key ~= "pos" and key ~= "sigil" then
            self[key] = value
          end
        end
      end
      tablex.foreachi(node, function (n) self:insert(node_to_type(n, resource)) end)
    end,

    insert = function (self, node)
      if type(node) ~= "table" then return nil end
      if not (self.elements and #self.elements >= 1 and self.elements[#self.elements]:append(node))
        and not self:modify(node)
        and not self:attach(node) then
        if not self.elements then error("Undefined insert "..node.type .. " into " .. self.type) end
        table.insert(self.elements, node)
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

FTL.blank_block = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      -- Penlight bug #347, should be self:super(node, resource)
      self._base._init(self, node, resource)
      local _, count = string.gsub(node[1], "\n", "")
      getmetatable(self).discardable = count == 0
    end
  })

FTL.Entry = function (node, resource)
  return node_to_type(node[1], resource)
end

FTL.Junk = class({
    _base = FluentNode,
  })

FTL.Message = class({
    attributeindex = {},
    _base = FluentNode,
    _init = function (self, node, resource)
      self.attributes = {}
      -- Penlight bug #347, should be self:super(node, resource)
      self._base._init(self, node, resource)
      -- Penlight bug #307, should be self:catch(self.get_attribute)
      self:catch(function (_, k) return self:get_attribute(k) end)
    end,
    get_attribute = function (self, attribute)
      return self.attributeindex[attribute] and self.attributes[self.attributeindex[attribute]] or nil
    end,
    format = function (self, parameters)
      return self.value:format(parameters)
    end,
  })

FTL.Term = function (node, resource)
  return FTL.Message(node, resource)
end

FTL.Identifier = class({
    _base = FluentNode,
    __mod = function (self, node)
      if node:is_a(FTL.VariantKey) then
        node.key = self
      else
        node.id = self
      end
      return node
    end,
    format = function (self)
      return self.name
    end
  })

FTL.Pattern = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self.elements = {}
      -- Penlight bug #347, should be self:super(node, resource)
      self._base._init(self, node, resource)
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
          local value = node.value
          if len >= 1 then
            value = string.gsub(value, strippref, "\n\n")
          end
          value = key == 1 and string.gsub(value, "^[\n ]+", "") or value
          value = key == #self.elements and string.gsub(value, "[\n ]+$", "") or value
          if string.len(value) == 0 then
            self.elements[key] = nil
          else
            self.elements[key].value = value
          end
        end
      end
      tablex.foreachi(self.elements, strip, striplen)
    end,
    __mul = function (self, node)
      if node:is_a(FTL.Message) or node:is_a(FTL.Attribute) or node:is_a(FTL.Variant) then
        node.value = self
        return node
      end
    end,
    format = function (self, parameters)
      local values = tablex.map_named_method('format', self.elements, parameters)
      return table.concat(values)
    end
  })

FTL.TextElement = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      getmetatable(self).appendable = true
      node.id = "TextElement"
      -- Penlight bug #347, should be self:super(node, resource)
      self._base._init(self, node, resource)
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

FTL.Placeable = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node, resource)
      node.id = "Placeable"
      node.expression = node_to_type(node.expression, resource)
      -- Penlight bug #347, should be self:super(node, resource)
      self._base._init(self, node, resource)
    end,
    __mod = function (self, node)
      if node:is_a(FTL.Pattern) then
        table.insert(node.elements, self)
        return node
      elseif node:is_a(FTL.Placeable) or node:is_a(FTL.SelectExpression) then
        node.expression = self
        return node
    else error("Undefined attach "..self.type.." to "..node.type) end
  end,
    format = function (self, parameters)
      return self.expression:format(parameters)
    end
  })

FTL.PatternElement = function (node, resource)
  if node.value then
    return FTL.TextElement(node, resource)
  else
    return FTL.Placeable(node, resource)
  end
end

FTL.StringLiteral = class({
    _base = FluentNode,
    format = function (self)
      return self.value
    end,
    __mod = function (self, node)
      if node:is_a(FTL.SelectExpression) then
        node.selector = self
        return node
      elseif node:is_a(FTL.Placeable) then
        node.expression = self
        return node
      elseif node:is_a(FTL.VariantKey) then
        node.key = self
        return node
      else error("Undefined attach "..self.type.." to "..node.type) end
    end
  })

FTL.NumberLiteral = class({
    _base = FluentNode,
    format = FTL.StringLiteral.format,
    __mod = FTL.StringLiteral.__mod
  })

FTL.VariableReference = class({
    _base = FluentNode,
    format = function (self, parameters)
      return parameters[self.id.name]
    end,
    __mod = FTL.StringLiteral.__mod
  })

FTL.MessageReference = class({
    _base = FluentNode,
    format = function (self, parameters)
      return self._resource:get_message(self.id.name):format(parameters)
    end
  })

FTL.TermReference = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      node.id = "TermReference"
      -- Penlight bug #347, should be self:super(node, resource)
      self._base._init(self, node, resource)
    end,
    __mul = function (self, node)
      if node:is_a(FTL.SelectExpression) then
        node.selector = self
        return node
      end
    end,
    format = function (self, parameters)
      return self._resource:get_term(self.id.name):format(parameters)
    end
  })

FTL._TermReference = FTL.TermReference

FTL.FunctionReference = class({
    _base = FluentNode,
    __mod = FTL.StringLiteral.__mod
  })

-- TODO: this needs locale data!
local tocldr = function (number)
  number = tonumber(number)
  if not number then return nil
  elseif number == 1 then return "one"
  else return "other" end
end

FTL.SelectExpression = class({
    selector = {},
    variants = {},
    _base = FluentNode,
    _init = function (self, node, resource)
      node.id = "SelectExpression"
      self.selector = {}
      self.variants = {}
      -- Penlight bug #347, should be self:super(node, resource)
      self._base._init(self, node, resource)
    end,
    format = function (self, parameters)
      local variant, result, default
      if parameters then
        if self.selector:is_a(FTL.VariableReference) then
          variant = parameters[tostring(self.selector.id)]
        else error("Undefined format "..self.type.." selector "..self.selector) end
      end
      for _, element in ipairs(self.variants) do
        if element.default then default = element end
        if variant
          and tostring(element.key) == tostring(variant)
          or  tostring(element.key) == tocldr(tostring(variant))
        then result = element end
      end
      return (result or default).value:format(parameters)
    end
  })

FTL._InlineExpression = function(node, resource)
  return FTL.InlineExpression(node, resource)
end

FTL.InlineExpression = function(node, resource)
  if node[1].id == "InlineExpression" then
    return FTL.Placeable(node, resource)
  else
    return node_to_type(node[1], resource)
  end
end

FTL.variant_list = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self.elements = {}
      -- Penlight bug #347, should be self:super(node, resource)
      self._base._init(self, node, resource)
    end,
    __mod = function (self, node)
      if node:is_a(FTL.SelectExpression) then
        tablex.insertvalues(node.variants, self.elements)
        return node
      else error("Undefined attach "..self.type.." to "..node.type) end
    end
  })

FTL.Variant = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      node.id = "Variant"
      node.default = node.default or false
      -- Penlight bug #347, should be self:super(node, resource)
      self._base._init(self, node, resource)
    end
  })

FTL.VariantKey = class({
    _base = FluentNode,
    __mod = function (self, node)
      if node:is_a(FTL.Variant) then
        node.key = self.key
        return node
      else error("Undefined attach "..self.type.." to "..node.type) end
    end
  })

FTL.DefaultVariant = function (node, resource)
  node.default = true
  return FTL.Variant(node, resource)
end

FTL.CallArguments = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      self.named = {}
      self.positional = {}
      -- Penlight bug #347, should be self:super(node, resource)
      self._base._init(self, node, resource)
    end,
    __mul = function (self, node)
      if node:is_a(FTL.FunctionReference) then
        node.arguments = self
        return node
      end
    end
  })

FTL.NamedArgument = class({
    _base = FluentNode,
  })

FTL.Comment = class({
    _base = FluentNode,
    _init = function (self, node, resource)
      getmetatable(self).appendable = true
      -- Penlight bug #347, should be self:super(node, resource)
      self._base._init(self, node, resource)
    end,
    __add = function (self, node)
      if node:is_a(self:is_a()) and node.appendable and self.appendable then
        node.content = (node.content or "") .. "\n" .. (self.content or "")
        return node
      end
    end,
    __mul = function (self, node)
      if node:is_a(FTL.Message) then
        node.comment = self
        return node
      end
    end
  })

FTL.GroupComment = class({
    _base = FluentNode,
    _init = FTL.Comment._init,
    __add = FTL.Comment.__add
  })

FTL.ResourceComment = class({
    _base = FluentNode,
    _init = FTL.Comment._init,
    __add = FTL.Comment.__add
  })

FTL.Attribute = class({
    _base = FluentNode,
    __mul = function (self, node)
      if node:is_a(FTL.Message) then
        table.insert(node.attributes, self)
        node.attributeindex[self.id.name] = #node.attributes
        return node
      elseif self:is_a(FTL.Pattern) then
        node.value = self
        return node
      end
    end,
    format = function (self, parameters)
      return self.value:format(parameters)
    end
  })

FTL.AttributeAccessor = class({
    _base = FluentNode,
    __mul = function (self, node)
      if node:is_a(FTL.TermReference) then
        node.attribute = self.id
        return node
      else error("Undefined attach "..self.type.." to "..node.type) end
    end
  })

FTL.CommentLine = function (node, resource)
  node.id = #node.sigil == 1 and "Comment"
          or #node.sigil == 2 and "GroupComment"
          or #node.sigil == 3 and "ResourceComment"
  return FTL[node.id](node, resource)
end

node_to_type = function (node, resource)
  if type(node) == "table" and type(node.id) == "string" then
    return FTL[node.id](node, resource)
  end
end

local FluentResource = class({
    type = "Resource",
    messageindex = {},
    termindex = {},

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
        if node:is_a(FTL.blank_block) then
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
      if node:is_a(FTL.Message) then
        local relevantindex = node.type == "Message" and self.messageindex or self.termindex
        relevantindex[node.id.name] = #self.body
      end
    end,

    get_message = function (self, identifier, isterm)
      local key = rawget(isterm and self.termindex or self.messageindex, string.match(identifier, "^(%a[-_%a%d]+)"))
      if not key then return end
      local entry = rawget(self, "body")[key]
      if not entry then return end
      local attr = string.match(identifier, "%.([(%a[-_%a%d]+)$")
      return attr and entry.attributes[entry.attributeindex[attr]] or entry
    end,

    get_term = function (self, identifier)
      return self:get_message(identifier, true)
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
