local Registry = {}

local entity_modules = {}

function Registry.register(key, module)
  if entity_modules[key] then
    error("entity module already mapped for " .. key)
  end

  entity_modules[key] = module
end

---@param ent Entity
function Registry.lookup(ent)
  return Registry.lookup_by_key(ent.__entity__)
end

function Registry.lookup_by_key(key)
  local mod = entity_modules[key]

  assert(mod, "entity module not found for " .. key)

  return mod
end

return Registry
