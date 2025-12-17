Player = Object:extend()

--[[
- anmiation state
  - attack
  - duck
  - duck
  - fall
  - game_over
  - happy
  - hurt
  - idle
  - jump
  - walk
- animation speed (walk vs run -> same state, different speed)
--]]

-- 120 x 120

local sprites = {
  attack = love.graphics.newArrayImage({
    "assets/player/player_attack_0.png",
    "assets/player/player_attack_1.png",
    "assets/player/player_attack_2.png",
    "assets/player/player_attack_3.png",
    "assets/player/player_attack_4.png",
    "assets/player/player_attack_5.png"
  }),
  duck = love.graphics.newImage("assets/player/player_duck.png"),
  fall = love.graphics.newImage("assets/player/player_fall.png"),
  game_over = love.graphics.newImage("assets/player/player_game_over.png"),
  happy = love.graphics.newArrayImage({ "assets/player/player_happy_0.png",
    "assets/player/player_happy_1.png" }),
  hurt = love.graphics.newImage("assets/player/player_hurt.png"),
  idle = love.graphics.newArrayImage({ "assets/player/player_idle_0.png",
    "assets/player/player_idle_1.png" }),
  jump = love.graphics.newImage("assets/player/player_jump.png"),
  walk = love.graphics.newArrayImage({
    "assets/player/player_walk_0.png",
    "assets/player/player_walk_1.png" })
}

love.graphics.draw(sprites.jump, 100, 100)

love.graphics.drawLayer(sprites.walk, 1, 50, 50)
love.graphics.drawLayer(sprites.walk, 2, 250, 50)
