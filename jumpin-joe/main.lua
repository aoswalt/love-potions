--[[
- scenes
  - main menu
  - play - (levels)
    - pause menu
    - end menu
- camera
- player
- enemies
- pickups
- levels/maps
]]

Object = require "lib/classic"
require "game"
require "scene"
require "scenes"

function love.load()
  G = Game()
  G:goToScene(MainMenu.name)
end

function love.update(dt)
  G:update(dt)
end

function love.draw()
  G:draw()
end
