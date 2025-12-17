MainMenu = Scene:extend()

MainMenu.name = 'main_menu'

function MainMenu:draw()
  love.graphics.print("Main Menu", 100, 100)
end

Scene.registry[MainMenu.name] = MainMenu
