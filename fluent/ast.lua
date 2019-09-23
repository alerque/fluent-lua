-- External dependencies
local class = require("pl.class")
local tablex = require("pl.tablex")

local FluentNode = class({
    _init = function (self, node)
      for key, value in pairs(node) do
        if type(key) == "string" then
          if key == "id" then
            if value == "CommentLine" then
              self.type =  #node.sigil == 1 and "Comment"
                        or #node.sigil == 2 and "GroupComment"
                        or #node.sigil == 3 and "ResourceComment"
                        or error("Unknown comment sigil: "..node.sigil..".")
            else
              self.type = value
            end
          elseif key == "pos" then
          elseif key == "sigil" then
          elseif key == "value" then
            local value = string.gsub(value, "^\n+ +", "")
            self[key] = value
          else
            self[key] = value
          end
        end
      end
    end
  })

local function ast_children (node)
  local children = {}
  for key, value in ipairs(node) do
    if type(key) == "number" then children[key] = value end
  end
  return children
end

local function dedent (content)
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

local parse_by_type = {

  Entry = function (self, node)
    return self(node[1])
  end,

  blank_block = function (self, node)
    local _, count = string.gsub(node[1], "\n", "")
    return count >= 1 and {} or nil
  end,

  Junk = function (self, node)
    node = ast_children(node)
    -- node.annotations = {}
    return node
  end,

  Message = function (self, node)
    node = ast_children(node)
    local ast = { id = node.id, value = {}, attributes = {} }
    for key, value in ipairs(node) do
      if value.id == "Identifier" then
        ast.id = self(value)
      elseif value.id == "Pattern" then
        ast.value = self(value)
      end
    end
    return ast
  end,

  Identifier = function (self, node)
    return ast_children(node)
  end,

  Term = function (self, node)
    return self:Message(node)
  end,

  Pattern = function (self, node)
    local stuff = ast_children(node)
    local ast = { elements = {} }
    local lasttype = "none"
    for key, value in ipairs(stuff) do
      if lasttype == value.id then
        ast.elements[#ast.elements] = ast.elements[#ast.elements].value .. value.value
      else
        table.insert(ast.elements, self(value))
        lasttype = value.id
      end
    end
    for key, value in ipairs(ast.elements) do
      if key == "value" then
        ast.elements[key] = dedent(value)
      end
    end
    return ast
  end,

  PatternElement = function (self, node)
    node = ast_children(node)
    node.type = "TextElement"
    return node
  end,

  Comment = function (self, node)
    return ast_children(node)
  end,

  GroupComment = function (self, node)
    return ast_children(node)
  end,

  ResourceComment = function (self, node)
    return ast_children(node)
  end,

}

setmetatable(parse_by_type, {
    __call = function (self, node)
      local ast = FluentNode(node)
      local stuff = self[ast.type](self, node)
      return stuff and tablex.merge(ast, stuff, true) or nil
    end
  })

local function munge_ast (node)
  local ast = FluentNode(node)
  local stash = nil
  ast.body = {}
  local entries = {}
  for key, value in ipairs(node) do
    if type(key) == "number" then
      table.insert(entries, parse_by_type(value))
    end
  end
  local flushcomments = function ()
    if stash then table.insert(ast.body, stash) end
    stash = nil
  end
  local stashcomment = function (node)
    if not stash then
      stash = node
    elseif stash.type == node.type then
      stash.content = (stash.content or "") .. "\n" .. (node.content or "")
    else
      flushcomments()
      stash = node
    end
  end
  for key, value in ipairs(entries) do
    if value.type:match("Comment$") then
      stashcomment(value)
    elseif value.type == "blank_block" then
      flushcomments()
    elseif value.type == "Message" or value.type == "Term" then
      if stash then
        if stash.type ~= "Comment" then
          flushcomments()
        else
          value.comment = stash
          stash = nil
        end
      end
      table.insert(ast.body, value)
    else
      flushcomments()
      table.insert(ast.body, value)
    end
  end
  flushcomments()
  return ast
end


local FluentAST = class({
    munge = function (self, ast)
      return munge_ast(ast)
    end
  })

return FluentAST
