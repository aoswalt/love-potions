local Registry = require('registry')
local Vector = require('vector')

---@class (exact) Particle: Entity
---@field package facing Vector normalized facing direction
---@field package speed number
---@field package lifetime number remaining lifetime

---@class ParticleModule: EntityModule
local Particle = {}

function Particle.type()
  return 'particle'
end

Registry.register(Particle.type(), Particle)

---create a particle
---@param opts table
---@return Particle
function Particle.new(opts)
  assert(opts.pos, 'particle does not have a position')

  ---@type Particle
  return {
    __type__ = Particle.type(),
    pos = Vector.clone(opts.pos),
    facing = Vector.clone(opts.facing or Vector.zero()),
    speed = opts.speed or 0,
    lifetime = opts.lifetime or 2,
  }
end

---update the particle
---@param particle Particle
---@param dt number
function Particle.update(particle, dt)
  if particle.dead then
    return
  end

  particle.lifetime = particle.lifetime - dt

  if particle.lifetime <= 0 then
    particle.dead = true
    return
  end

  particle.pos.x = particle.pos.x + particle.facing.x * particle.speed * dt
  particle.pos.y = particle.pos.y + particle.facing.y * particle.speed * dt
end

---draw the particle
---@param particle Particle
function Particle.draw(particle)
  if particle.dead then
    return
  end

  love.graphics.circle('fill', particle.pos.x, particle.pos.y, 10)
end

return Particle
