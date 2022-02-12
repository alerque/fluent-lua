-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")

-- Private namespace to organize various node classes
local FTL = {}

-- Utility function to cast ast nodes from the syntax parser to corresponding class instances
local leaf_to_node = function (node)
  if type(node) == "table" and type(node.id) == "string" then
    return FTL[node.id](node)
  end
end

local _resource

local FluentNode = class({
    _name = "FluentNode",

    _init = function (self, ast)
      for key, value in pairs(ast) do
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
      tablex.foreachi(ast, function (leaf) self:inject(leaf_to_node(leaf)) end)
    end,

    inject = function (self, node)
      if type(node) ~= "table" then return nil end
      local elements = rawget(self, "elements")
      if not (elements and #elements >= 1 and elements[#elements]:append(node))
        and not self:modify(node)
        and not self:attach(node) then
        if not elements then
          error("Undefined injection "..node.type .. " into " .. self.type)
        end
        table.insert(elements, node)
      end
    end,

    dump_ast = function (self)
      local ast = { type = self.type }
      for k, v in pairs(self) do ast[k] = v end
      return ast
    end,

    append = function (self, node)
      local func = node and rawget(getmetatable(node), "__add")
      return node and type(func) == "function" and node + self
    end,

    modify = function (self, node)
      local func = node and rawget(getmetatable(node), "__mod")
      return node and type(func) == "function" and node % self
    end,

    attach = function (self, node)
      local func = node and rawget(getmetatable(node), "__mul")
      return node and type(func) == "function" and node * self
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

FTL.blank_block = class(FluentNode)
FTL.blank_block._name = "blank_block"

function FTL.blank_block:_init (node)
  self:super(node)
  local _, count = string.gsub(node[1], "\n", "")
  getmetatable(self).discardable = count == 0
end

FTL.Entry = function (node)
  return leaf_to_node(node[1])
end

FTL.Junk = class(FluentNode)
FTL.Junk._name = "Junk"

FTL.Message = class(FluentNode)
FTL.Message._name = "Message"

function FTL.Message:_init (node)
  self.attributes = {}
  rawset(getmetatable(self), "attribute_map", {})
  self:super(node)
  -- Penlight bug #307, should be — self:catch(self.get_attribute)
  self:catch(function (_, attribute) return self:get_attribute(attribute) end)
end

function FTL.Message:set_attribute (attribute)
  local id = attribute.id.name
  local attrs = rawget(self, "attributes")
  local map = rawget(getmetatable(self), "attribute_map")
  local k = map[attribute.id.name]
  if not k then
    k = #attrs + 1
  end
  attrs[k] = attribute
  map[attribute.id.name] = k
  rawset(getmetatable(self), id, attrs[k])
end

function FTL.Message:get_attribute (attribute)
  return rawget(getmetatable(self), attribute)
end

function FTL.Message:format (parameters)
  return self.value:format(parameters)
end

FTL.Term = FTL.Message

FTL.Identifier = class(FluentNode)
FTL.Identifier._name = "Identifier"

function FTL.Identifier:__mod (node)
  if node:is_a(FTL.VariantKey) then
    node.key = self
  else
    node.id = self
  end
  return node
end

function FTL.Identifier:format ()
  return self.name
end

FTL.Pattern = class(FluentNode)
FTL.Pattern._name = "Pattern"

function FTL.Pattern:_init (node)
  self.elements = {}
  self:super(node)
  self:dedent()
end

function FTL.Pattern:dedent ()
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
end

function FTL.Pattern:__mul (node)
  if node:is_a(FTL.Message) or node:is_a(FTL.Attribute) or node:is_a(FTL.Variant) then
    node.value = self
    return node
  end
end

function FTL.Pattern:format (parameters)
  local values = tablex.map_named_method('format', self.elements, parameters)
  return table.concat(values)
end

FTL.TextElement = class(FluentNode)
FTL.TextElement._name ="TextElement"

function FTL.TextElement:_init (node)
  getmetatable(self).appendable = true
  node.id = "TextElement"
  self:super(node)
end

function FTL.TextElement:__add (node)
  if self:is_a(node:is_a()) and self.appendable and node.appendable then
    node.value = (node.value or "") .. "\n" .. (self.value or "")
    return node
  end
end

function FTL.TextElement:format ()
  return self.value
end

FTL.Placeable = class(FluentNode)
FTL.Placeable._name = "Placeable"

function FTL.Placeable:_init (node)
  getmetatable(self).appendable = true
  node.id = "Placeable"
  node.expression = leaf_to_node(node.expression)
  self:super(node)
end

function FTL.Placeable:__mod (node)
  if node:is_a(FTL.Pattern) then
    table.insert(node.elements, self)
    return node
  elseif node:is_a(FTL.Placeable) or node:is_a(FTL.SelectExpression) then
    node.expression = self
    return node
  else error("Undefined attach "..self.type.." to "..node.type) end
end

function FTL.Placeable:format (parameters)
  return self.expression:format(parameters)
end

FTL.PatternElement = function (node)
  if node.value then
    return FTL.TextElement(node)
  else
    return FTL.Placeable(node)
  end
end

FTL.StringLiteral = class(FluentNode)
FTL.StringLiteral._name = "StringLiteral"

function FTL.StringLiteral:format ()
  return self.value
end

function FTL.StringLiteral:__mod (node)
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

FTL.NumberLiteral = class(FluentNode)
FTL.NumberLiteral._name = "NumberLiteral"
FTL.NumberLiteral.format = FTL.StringLiteral.format
FTL.NumberLiteral.__mod = FTL.StringLiteral.__mod

FTL.VariableReference = class(FluentNode)
FTL.VariableReference._name = "VariableReference"
FTL.VariableReference.__mod = FTL.StringLiteral.__mod

function FTL.VariableReference:format (parameters)
  return parameters[self.id.name]
end


FTL.MessageReference = class(FluentNode)
FTL.MessageReference._name = "MessageReference"

function FTL.MessageReference:format (parameters)
  return _resource:get_message(self.id.name):format(parameters)
end

FTL.TermReference = class(FluentNode)
FTL.TermReference._name = "TermReference"

function FTL.TermReference:_init (node)
  node.id = "TermReference"
  self:super(node)
end

function FTL.TermReference:__mul (node)
  if node:is_a(FTL.SelectExpression) then
    node.selector = self
    return node
  end
end

function FTL.TermReference:format (parameters)
  return _resource:get_term(self.id.name):format(parameters)
end

FTL._TermReference = FTL.TermReference

FTL.FunctionReference = class(FluentNode)
FTL.FunctionReference._name = "FunctionReference"
FTL.FunctionReference.__mod = FTL.StringLiteral.__mod

-- TODO: this needs locale data!
local tocldr = function (number)
  number = tonumber(number)
  if not number then return nil
  elseif number == 1 then return "one"
  else return "other" end
end

FTL.SelectExpression = class(FluentNode)
FTL.SelectExpression._name = "SelectExpression"

function FTL.SelectExpression:_init (node)
  node.id = "SelectExpression"
  self.selector = {}
  self.variants = {}
  self:super(node)
end

function FTL.SelectExpression:format (parameters)
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

FTL.InlineExpression = function(node)
  if node[1].id == "InlineExpression" then
    return FTL.Placeable(node)
  else
    return leaf_to_node(node[1])
  end
end

FTL._InlineExpression = FTL.InlineExpression

FTL.variant_list = class(FluentNode)
FTL.variant_list._name = "variant_list"

function FTL.variant_list:_init (node)
  self.elements = {}
  self:super(node)
end

function FTL.variant_list:__mod (node)
  if node:is_a(FTL.SelectExpression) then
    tablex.insertvalues(node.variants, self.elements)
    return node
  else error("Undefined attach "..self.type.." to "..node.type) end
end

FTL.Variant = class(FluentNode)
FTL.Variant._name = "Variant"

function FTL.Variant:_init (node)
  node.id = "Variant"
  node.default = node.default or false
  self:super(node)
end

FTL.VariantKey = class(FluentNode)
FTL.VariantKey._name = "VariantKey"

function FTL.VariantKey:__mod (node)
  if node:is_a(FTL.Variant) then
    node.key = self.key
    return node
  else error("Undefined attach "..self.type.." to "..node.type) end
end

FTL.DefaultVariant = function (node)
  node.default = true
  return FTL.Variant(node)
end

FTL.CallArguments = class(FluentNode)
FTL.CallArguments._name = "CallArguments"

function FTL.CallArguments:_init (node)
  self.named = {}
  self.positional = {}
  self:super(node)
end

function FTL.CallArguments:__mul (node)
  if node:is_a(FTL.FunctionReference) then
    node.arguments = self
    return node
  end
end

FTL.NamedArgument = class(FluentNode)
FTL.NamedArgument._name = "NamedArgument"

FTL.Comment = class(FluentNode)
FTL.Comment._name = "Comment"

function FTL.Comment:_init (node)
  getmetatable(self).appendable = true
  self:super(node)
end

function FTL.Comment:__add (node)
  if node:is_a(self:is_a()) and node.appendable and self.appendable then
    node.content = (node.content or "") .. "\n" .. (self.content or "")
    return node
  end
end

function FTL.Comment:__mul (node)
  if node:is_a(FTL.Message) then
    node.comment = self
    return node
  end
end

FTL.GroupComment = class(FluentNode)
FTL.GroupComment._name = "GroupComment"
FTL.GroupComment._init = FTL.Comment._init
FTL.GroupComment.__add = FTL.Comment.__add

FTL.ResourceComment = class(FluentNode)
FTL.ResourceComment._name = "ResourceComment"
FTL.ResourceComment._init = FTL.Comment._init
FTL.ResourceComment.__add = FTL.Comment.__add

FTL.Attribute = class(FluentNode)
FTL.Attribute._name = "Attribute"

function FTL.Attribute:__mul (node)
  if node:is_a(FTL.Message) then
    node:set_attribute(self)
    return node
  elseif self:is_a(FTL.Pattern) then
    node.value = self
    return node
  end
end

function FTL.Attribute:format (parameters)
  return self.value:format(parameters)
end

FTL.AttributeAccessor = class(FluentNode)
FTL.AttributeAccessor._name = "AttributeAccessor"

function FTL.AttributeAccessor:__mul (node)
  if node:is_a(FTL.TermReference) then
    node.attribute = self.id
    return node
  else error("Undefined attach "..self.type.." to "..node.type) end
end

FTL.CommentLine = function (node)
  node.id = #node.sigil == 1 and "Comment"
          or #node.sigil == 2 and "GroupComment"
          or #node.sigil == 3 and "ResourceComment"
  return FTL[node.id](node)
end

local FluentResource = class({
    _name = "FluentResource",
    type = "Resource",

    _init = function (self, ast)
      _resource = self
      ast = ast or {}
      self.body = {}
      rawset(getmetatable(self), "body_map", {})
      local _stash
      local flush = function ()
        if _stash then
          self:load_node(_stash)
          _stash = nil
        end
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
        local node = leaf_to_node(leaf)
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
      self:catch(function (_, identifier) return self:get_message(identifier) end)
    end,

    load_node = function (self, node)
      local id_name = node.id and node.id.name or nil
      local body = self.body
      local map = rawget(getmetatable(self), "body_map")
      if id_name then
        if node:is_a(FTL.Message) and node.type == "Term" then
          id_name = "-" .. id_name
        end
      end
      local k = map[id_name] or #body + 1
      body[k] = node
      map[id_name] = k
    end,

    get_message = function (self, identifier, isterm)
      local id = string.match(identifier, "^(%a[-_%a%d]+)")
      if not id then return end
      local name = (isterm and "-" or "") .. id
      local map = rawget(getmetatable(self), "body_map")
      local k = map[name]
      local entry = self.body[k]
      if not entry then return end
      local attr = string.match(identifier, "%.([(%a[-_%a%d]+)$")
      return attr and entry:get_attribute(attr) or entry
    end,

    get_term = function (self, identifier)
      return self:get_message(identifier, true)
    end,

    dump_ast = function (self)
      local ast =  { type = "Resource", body = {} }
      for _, v in ipairs(self.body) do table.insert(ast.body, v:dump_ast()) end
      return ast
    end,

    __add = function (self, other)
      if not self:is_a(other:is_a()) then error("Cannot merge unlike types") end
      for _, node in ipairs(other.body) do
        self:load_node(node)
      end
      return self
    end

  })

return FluentResource
