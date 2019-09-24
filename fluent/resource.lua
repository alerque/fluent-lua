-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")

local node_types = {}

local FluentNode = class({
    discardable = false,
    mergable = false,

    _init = function (self, node)
      for key, value in pairs(node) do
        if type(key) == "string" then
          if key == "id" then
            self.type = value
          elseif key == "pos" then
          elseif key == "sigil" then
            -- drop unused keys
          elseif key == "value" then
            local value = string.gsub(value, "^\n+ +", "")
            self[key] = value
          else
            self[key] = value
          end
        end
      end
      tablex.insertvalues(self, tablex.imap(node_to_class, node))
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
      for key, value in ipairs(self) do
        if value.type == "Identifier" then
          self.id = value
          self[key] = nil
        elseif value.type == "Pattern" then
          -- TODO: can their be more than one of these?
          self.value = value
          self[key] = nil
        end
      end
    end,
    format = function (self, parameters)
      return self.value[1].value
    end
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
    end
  })
-- function (self, node)
--   local ast = { elements = {} }
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
--   return ast
-- end,

node_types.TextElement = class({
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end
  })

node_types.PatternElement = function (node)
  return node_types.TextElement(node)
end

node_types.Comment = class({
    mergable = true,
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end
  })

node_types.GroupComment = class({
    mergable = true,
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end
  })

node_types.ResourceComment = class({
    mergable = true,
    _base = FluentNode,
    _init = function (self, node)
      self:super(node)
    end
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
  local common = function(min)
    local i = 0
    local s = ""
    while i < min do
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

    _init = function (self, ast)
      local stash = nil
      local stashcomment = function (node)
        if not stash then
          stash = node
        elseif stash.type == node.type then
          stash.content = (stash.content or "") .. "\n" .. (node.content or "")
        else
          flushcomments()
          stashcomment(node)
        end
      end
      local flushcomments = function ()
        if stash then table.insert(self, stash) end
        stash = nil
      end
      -- TODO: eliminate double iteration by looking ahead?
      local elements = tablex.imap(node_to_class, ast)
      for _, node in ipairs(elements) do
        if node.mergable then
          stashcomment(node)
        elseif node:is_a(node_types.blank_block) then
          if not node.discardable then
            flushcomments()
          end
        elseif node:is_a(node_types.Message) or node:is_a(Term) then
          if stash then
            if stash.type ~= "Comment" then
              flushcomments()
            else
              node.comment = stash
              stash = nil
            end
          end
          local i = table.insert(self, node)
          if node:is_a(node_types.Message) then
            self[node.id.name] = node
          end
        else
          flushcomments()
          table.insert(self, node)
        end
      end
      flushcomments()
    end,

    lookup = function (self, identifier)
      return self[identifier] or self:search(identifier)
    end,

    search = function (self, identifier)
      if true then return nil end
      local is_identifier = function(node, identifier)
        return node.id.type == "Identifier"
            and node.id.name == identifier
            and node
            or nil
      end
      local i, node = tablex.find_if(self, is_identifier, identifier)
      return node
    end

  })

return FluentResource
