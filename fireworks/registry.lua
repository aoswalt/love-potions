local Registry = {}

-- local modules = {}
-- local key_field = '__entity__'
--
-- function Registry.key_field()
--   return key_field
-- end
--
-- function Registry.register(key, module)
--   if modules[key] then
--     error("entity module already mapped for " .. key)
--   end
--
--   modules[key] = module
-- end
--
-- ---@param ent_or_key Entity | string
-- function Registry.lookup(ent_or_key)
--   local key
--
--   if type(ent_or_key) == 'string' then
--     key = ent_or_key
--   elseif type(ent_or_key) == 'table' then
--     key = ent_or_key[key_field]
--     assert(key, 'no value found under ' .. key_field .. ' for lookup')
--   else
--     error('invalid type for Registry lookup, got ' .. type(ent_or_key))
--   end
--
--   local mod = modules[key]
--
--   assert(mod, "entity module not found for " .. key)
--
--   return mod
-- end

function Registry.new(key_field)
  assert(key_field, 'key_field required for Registry definition')

  local new_registry = {
    __key_field__ = key_field,
    modules = {},
  }

  function new_registry.key_field()
    return new_registry.key_field
  end

  function new_registry.register(key, module)
    if new_registry.modules[key] then
      error("entity module already mapped for " .. key)
    end

    new_registry.modules[key] = module
  end

  ---@param ent_or_key Entity | string
  function new_registry.lookup(ent_or_key)
    local key

    if type(ent_or_key) == 'string' then
      key = ent_or_key
    elseif type(ent_or_key) == 'table' then
      key = ent_or_key[new_registry.__key_field__]
      assert(key, 'no value found under ' .. new_registry.__key_field__ .. ' for lookup')
    else
      error('invalid type for Registry lookup, got ' .. type(ent_or_key))
    end

    local mod = new_registry.modules[key]

    assert(mod, "entity module not found for " .. key)

    return mod
  end

  return new_registry
end

return Registry.new('__entity__')
