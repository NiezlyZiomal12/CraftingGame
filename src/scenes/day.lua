local DayCycle = require("src.day_cycle")
local Inventory = require("src.inventory")

local scene = {}
local calendar = DayCycle.new()
local inventory = Inventory.new()
local titleFont
local bodyFont
local buttonFont

local colors = {
    { 0.48, 0.73, 0.90 },
    { 0.96, 0.79, 0.47 },
    { 0.88, 0.52, 0.43 },
    { 0.19, 0.25, 0.43 },
}

local function buttonBounds()
    local width, height = love.graphics.getDimensions()
    local buttonWidth, buttonHeight = 132, 38
    return width - buttonWidth - 24, height - buttonHeight - 24, buttonWidth, buttonHeight
end

local function advance()
    DayCycle.advance(calendar)
end

function scene.load()
    titleFont = love.graphics.newFont(26)
    bodyFont = love.graphics.newFont(16)
    buttonFont = love.graphics.newFont(14)
    inventory:load()
end

function scene.draw()
    local width, height = love.graphics.getDimensions()
    local color = colors[calendar.stamp]
    love.graphics.clear(color[1], color[2], color[3])

    local darkText = calendar.stamp ~= 4
    if darkText then
        love.graphics.setColor(0.13, 0.16, 0.22)
    else
        love.graphics.setColor(0.96, 0.96, 1)
    end

    love.graphics.setFont(bodyFont)
    local date = string.format("Week %d  |  Day %d (%s)", calendar.week, calendar.day, DayCycle.weekdays[calendar.day])
    love.graphics.printf(date, 20, 18, width * 0.55, "left")

    love.graphics.setFont(titleFont)
    love.graphics.printf(DayCycle.stamps[calendar.stamp], width * 0.55 - 20, 18, width * 0.45, "right")
    inventory:draw()

    local x, y, buttonWidth, buttonHeight = buttonBounds()
    love.graphics.setColor(0.13, 0.16, 0.22)
    love.graphics.rectangle("fill", x, y, buttonWidth, buttonHeight, 10, 10)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(buttonFont)
    love.graphics.printf("Next time", x, y + (buttonHeight - buttonFont:getHeight()) / 2, buttonWidth, "center")
end

function scene.mousepressed(x, y, button)
    if button ~= 1 then return end

    if inventory:mousepressed(x, y, button) then return end

    local bx, by, bw, bh = buttonBounds()
    if x >= bx and x <= bx + bw and y >= by and y <= by + bh then
        advance()
    end
end

function scene.wheelmoved(x, y)
    inventory:wheelmoved(x, y)
end

function scene.keypressed(key)
    if key == "space" or key == "return" or key == "kpenter" then
        advance()
    end
end

return scene
