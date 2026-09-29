local DayScene = require("src.scenes.day")

function love.load()
    love.window.setTitle("Crafting Game")
    love.window.setMode(800, 500, { resizable = true, minwidth = 480, minheight = 320 })
    DayScene.load()
end

function love.draw()
    DayScene.draw()
end

function love.mousepressed(x, y, button)
    DayScene.mousepressed(x, y, button)
end

function love.keypressed(key)
    DayScene.keypressed(key)
end
