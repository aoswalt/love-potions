Game = Object:extend()

function Game:new()
  self.activeScene = nil
  self.memoryScenes = {}
end

function Game:update(dt)
  if not self.activeScene then
    return
  end

  self.activeScene:update(dt)
end

function Game:draw()
  if not self.activeScene then
    return
  end

  self.activeScene:draw()
end

function Game:goToScene(name)
  if self.activeScene then
    local destroy = self.activeScene.onExit()
    if destroy then
      self.memoryScenes[name] = nil
    end
  end

  if self.memoryScenes[name] then
    self.activeScene = self.memoryScenes[name]
  else
    local newScene = assert(Scene.registry[name])()
    self.activeScene = newScene
    self.memoryScenes[name] = newScene
  end

  self.activeScene.onEnter()
end
