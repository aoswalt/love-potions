-- https://luals.github.io/wiki/annotations/

---@meta

---@class (exact) Entity
---@field __type__ string the internal type
---@field pos Vector position
---@field dead? boolean is the particle dead

---@class EntityModule
---@field type function(): string
---@field update function(entity: Entity, dt: number): nil
---@field draw function(entity: Entity): nil
