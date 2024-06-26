-- External dependencies
local class = require("pl.class")

-- Private namespace to organize various node classes
local FluentMessages = require("fluent.messages")

local FluentResource = class()
FluentResource._name = "FluentResource"
FluentResource.type = "Resource"

function FluentResource:_init (ast)
   ast = ast or {}
   self.body = setmetatable({}, {
      map = {},
   })
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
      local node = FluentMessages[leaf.id](leaf, self)
      if node:is_a(FluentMessages.blank_block) then
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
   -- Work around Penlight #307
   -- self:catch(self.get_message)
   self:_patch_init()
   return self
end

-- Work around Penlight #307
function FluentResource:_patch_init ()
   if type(rawget(getmetatable(self), "__index")) ~= "function" then
      self:catch(function (_, identifier)
         return self:get_message(identifier)
      end)
   end
end

function FluentResource:load_node (node)
   self:_patch_init()
   local body = self.body
   local k = #body + 1
   body[k] = node
   local id_name = node.id and node.id.name or nil
   if id_name then
      local map = getmetatable(body).map
      if node:is_a(FluentMessages.Message) and node.type == "Term" then
         id_name = "-" .. id_name
      end
      map[id_name] = k
      -- TODO Fix with working catch?
      -- getmetatable(self)[id_name] = node
   end
end

function FluentResource:get_message (identifier, isterm)
   -- local raw = rawget(self, identifier)
   -- if raw then return raw end
   -- if not rawget(self, "id") then
   --   error("Penlight bug, please use get_message() rather than table index syntax for now")
   -- end
   local id = string.match(identifier, "^(%a[-_%a%d]+)")
   if not id then
      return
   end
   local name = (isterm and "-" or "") .. id
   local body = self.body
   local map = getmetatable(body).map
   local k = map[name]
   local entry = body[k]
   if not entry then
      return
   end
   local attribute = string.match(identifier, "%.([(%a[-_%a%d]+)$")
   return attribute and entry:get_attribute(attribute) or entry
end

function FluentResource:format (identifier, parameters)
   local message = self:get_message(identifier)
   return message:format(parameters)
end

function FluentResource:get_term (identifier)
   return self:get_message(identifier, true)
end

function FluentResource:dump_ast ()
   local ast = { type = "Resource", body = {} }
   for _, node in ipairs(self.body) do
      table.insert(ast.body, node:dump_ast())
   end
   return ast
end

function FluentResource:__add (other)
   if not self:is_a(other:is_a()) then
      error("Cannot merge unlike types")
   end
   for _, node in ipairs(other.body) do
      node:set_parent(self)
      self:load_node(node)
   end
   return self
end

return FluentResource
