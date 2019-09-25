-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")

local node_types = {}
local node_to_class
local dedent

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
      if (node[1] and #node > 0) then
        self.elements = {}
        tablex.insertvalues(self.elements, tablex.imap(node_to_class, node))
      end
    end,

    dump_ast = function (self)
      local ast = { type = self.type }
      for k, v in pairs(self) do ast[k] = v end
      ast.identifier = nil
      return ast
    end,

    append = function (self, node)
      if type(self.__add) == "function"
          and self.appendable
          and node.appendable
          and self:is_a(node:is_a())
        then
        return self + node
      else
        return false
      end
    end,

    attach = function (self, node)
      if node and
        type(node.__mul) == "function"
        then
        return self * node
      else
        return false
      end
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

-- TODO: can their ever be more than 1 entry?
node_types.Entry = function(node)
  return node_to_class(node[1])
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
      for key, value in ipairs(self.elements) do
        if value:is_a(node_types.Identifier) then
          self.identifier = value.name
          self.id = value
          self.elements[key] = nil
        elseif value:is_a(node_types.Pattern) then
          self.value = value
          self.elements[key] = nil
        end
      end
      if #self.elements == 0 then self.elements = nil end
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
      -- TODO: merge sequential mergables in elements
      -- TODO: move dedent to here after merge?
    end,
    format = function (self, parameters)
      local value = #self.elements >= 2 and dedent() or self.elements[1].value
      -- Todo parse elements and actually format a value
      return value, parameters
    end
  })
--   local lasttype = "none"
--   for key, value in ipairs(stuff) do
--     if lasttype == value.id then
--       ast.elements[#ast.elements] = ast.elements[#ast.elements].value .. value.value
--     else
--       table.insert(ast.elements, self(value))
--       lasttype = value.id
--     end
--   end
--   for key, value in ipairs(ast.elements) do
--     if key == "value" then
--       ast.elements[key] = dedent(value)
--     end
--   end

node_types.TextElement = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end
  })

node_types.PatternElement = function (node)
  node.id = "TextElement"
  return node_types.TextElement(node)
end

node_types.Comment = class({
    appendable = true,
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end,
    __add = function (self, node)
      self.content = (self.content or "") .. "\n" .. (node.content or "")
    end,
    __mul = function (self, node)
      self.comment = node
      return self
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

node_to_class = function (node)
  if type(node.id) ~= "string" then return nil end
  return node_types[node.id](node)
end

dedent = function (content)
  local min
  for indent in string.gmatch(content, "\n *%S") do
    min = min and math.min(min, #indent) or #indent
  end
  local common = function(shortest)
    local i = 0
    local s = ""
    while i < shortest do
      s = s .. " "
      i = i + 1
    end
    return s
  end
  local sp = common(min-2)
  local rep = string.gsub(content, "\n"..sp, "\n")
  return rep
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
        end
        _stash = nil
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
      -- TODO: eliminate double iteration by looking ahead?
      local elements = tablex.imap(node_to_class, ast)
      for _, node in ipairs(elements) do
        if node.appendable then
          stash(node)
        elseif node:is_a(node_types.blank_block) then
          if not node.discardable then
            flush()
          end
        elseif node:attach(_stash) and flush() then
          self:insert(node)
        else
          flush()
          self:insert(node)
        end
      end
      flush()
      -- self:catch(function (self, identifier) return self:get_message(identifier) end)
    end,

    insert = function (self, node)
      table.insert(self.body, node)
      if node:is_a(node_types.Message) then
        self.index[node.identifier] = #self.body
      end
    end,

    get_message = function (self, identifier)
      return self.index[identifier] and self.body[self.index[identifier]]
    end,

    dump_ast = function (self)
      local ast =  { type = "Resource", body = {} }
      for _, v in ipairs(self.body) do table.insert(ast.body, v:dump_ast()) end
      return ast
    end

  })

return FluentResource
