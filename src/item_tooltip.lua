local items = require("src.items")

local Tooltip = {}

function Tooltip.draw(itemId, quantity, panelX, panelWidth, titleFont, detailFont, quantityLabel)
    local item = items[itemId]
    if not item then return end

    local x = panelX + 12
    local width = panelWidth - 24
    local textX = x + 10
    local textWidth = width - 20
    local details = {
        "ID: " .. itemId,
        (quantityLabel or "Quantity") .. ": " .. quantity,
        "Type: " .. item.type,
        "Rarity: " .. item.rarity,
        "Weight: " .. item.weight,
        "Sell price: " .. item.sellPrice .. " coins",
        "Slot: " .. (item.equipmentSlot or "None"),
        "Strong power: " .. item.strongPower,
        "Survivability: " .. item.survivability,
        "Looting: " .. item.looting,
    }
    local lineHeight = 15
    local descriptionY = 32 + #details * lineHeight + 8
    local _, wrapped = detailFont:getWrap(item.description, textWidth)
    local height = descriptionY + #wrapped * detailFont:getHeight() + 10
    local _, mouseY = love.mouse.getPosition()
    local screenHeight = love.graphics.getHeight()
    local y = math.max(8, math.min(mouseY + 12, screenHeight - height - 8))

    love.graphics.setColor(0.08, 0.10, 0.15, 0.97)
    love.graphics.rectangle("fill", x, y, width, height, 7, 7)
    love.graphics.setColor(0.85, 0.88, 0.94)
    love.graphics.rectangle("line", x, y, width, height, 7, 7)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(titleFont)
    love.graphics.print(item.name, textX, y + 8)
    love.graphics.setFont(detailFont)
    for index, detail in ipairs(details) do
        love.graphics.print(detail, textX, y + 32 + (index - 1) * lineHeight)
    end
    love.graphics.printf(item.description, textX, y + descriptionY, textWidth, "left")
end

return Tooltip
