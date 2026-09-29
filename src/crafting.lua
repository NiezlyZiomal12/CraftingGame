local items = require("src.items")
local recipes = require("src.recipes")

local Crafting = {}
Crafting.__index = Crafting

local cardHeight = 90
local cardStep = 100

local function inside(x, y, bx, by, bw, bh)
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, maximum))
end

local function buttonBounds()
    local width, height = love.graphics.getDimensions()
    return width - 275, height - 60, 100, 38
end

local function panelBounds()
    local width, height = love.graphics.getDimensions()
    local panelWidth = math.min(350, math.floor(width * 0.42))
    return width - panelWidth - 20, 50, math.min(350, math.floor(width * 0.48)), height - 120
end

local function listLayout(panelX, panelY, panelWidth, panelHeight)
    local listX, listY = panelX + 12, panelY + 48
    local listHeight = panelHeight - 60
    local contentHeight = math.max(0, #recipes * cardStep - (cardStep - cardHeight))
    local maxScroll = math.max(0, contentHeight - listHeight)
    local listWidth = panelWidth - (maxScroll > 0 and 36 or 24)
    return listX, listY, listWidth, listHeight, contentHeight, maxScroll
end

function Crafting.new(inventory)
    return setmetatable({ inventory = inventory, open = false, scroll = 0 }, Crafting)
end

function Crafting:load()
    self.titleFont = love.graphics.newFont(16)
    self.rowFont = love.graphics.newFont(13)
    self.buttonFont = love.graphics.newFont(14)
    self.tooltipFont = love.graphics.newFont(13)
end

function Crafting:close()
    self.open = false
end

function Crafting:canCraft(recipe)
    if not items[recipe.result.id] then return false end
    for _, ingredient in ipairs(recipe.ingredients) do
        if not items[ingredient.id] or self.inventory:count(ingredient.id) < ingredient.quantity then
            return false
        end
    end
    return true
end

function Crafting:craft(recipe)
    if not self:canCraft(recipe) then return false end
    for _, ingredient in ipairs(recipe.ingredients) do
        self.inventory:remove(ingredient.id, ingredient.quantity)
    end
    self.inventory:add(recipe.result.id, recipe.result.quantity)
    return true
end

function Crafting:mousepressed(x, y, button, isMorning)
    if button ~= 1 or not isMorning then return false end

    local bx, by, bw, bh = buttonBounds()
    if inside(x, y, bx, by, bw, bh) then
        self.open = not self.open
        return true
    end

    if not self.open then return false end

    local px, py, pw, ph = panelBounds()
    if not inside(x, y, px, py, pw, ph) then return false end

    local lx, ly, lw, lh = listLayout(px, py, pw, ph)
    if inside(x, y, lx, ly, lw, lh) then
        for index, recipe in ipairs(recipes) do
            local cardY = ly + (index - 1) * cardStep - self.scroll
            local craftX, craftY = lx + 8, cardY + 65
            if inside(x, y, craftX, craftY, lw - 16, 21) then
                self:craft(recipe)
                break
            end
        end
    end

    return true
end

function Crafting:wheelmoved(_, y, isMorning)
    if not isMorning or not self.open then return end

    local mouseX, mouseY = love.mouse.getPosition()
    local px, py, pw, ph = panelBounds()
    if not inside(mouseX, mouseY, px, py, pw, ph) then return end

    local _, _, _, _, _, maxScroll = listLayout(px, py, pw, ph)
    self.scroll = clamp(self.scroll - y * cardStep, 0, maxScroll)
end

local function hoveredRecipe(mouseX, mouseY, lx, ly, lw, lh, scroll)
    if not inside(mouseX, mouseY, lx, ly, lw, lh) then return nil end
    for index, recipe in ipairs(recipes) do
        local cardY = ly + (index - 1) * cardStep - scroll
        if inside(mouseX, mouseY, lx, cardY, lw, cardHeight) then
            return recipe
        end
    end
end

local function drawCard(crafting, recipe, x, y, width)
    local available = crafting:canCraft(recipe)
    love.graphics.setColor(0.21, 0.26, 0.35)
    love.graphics.rectangle("fill", x, y, width, cardHeight, 6, 6)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(crafting.titleFont)
    love.graphics.print(items[recipe.result.id].name, x + 8, y + 5)

    love.graphics.setFont(crafting.rowFont)
    for index, ingredient in ipairs(recipe.ingredients) do
        local owned = crafting.inventory:count(ingredient.id)
        if owned >= ingredient.quantity then
            love.graphics.setColor(0.75, 0.77, 0.13)
        else
            love.graphics.setColor(1, 0.58, 0.54)
        end
        local lineY = y + 28 + (index - 1) * 18
        love.graphics.print(ingredient.quantity .. " " .. items[ingredient.id].name, x + 8, lineY)
        love.graphics.printf("have " .. owned, x + 8, lineY, width - 16, "right")
    end

    if available then
        love.graphics.setColor(0.25, 0.49, 0.34)
    else
        love.graphics.setColor(0.38, 0.39, 0.42)
    end
    love.graphics.rectangle("fill", x + 8, y + 65, width - 16, 21, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(crafting.buttonFont)
    love.graphics.printf("Craft", x + 8, y + 67, width - 16, "center")
end

local function drawTooltip(crafting, itemId, panelX, panelY, panelWidth, panelHeight)
    local item = items[itemId]
    if not item then return end

    local font = crafting.tooltipFont
    local description = item.description or ""
    local padding = 10
    local lineHeight = 16
    local tooltipX = panelX + 12
    local tooltipWidth = panelWidth - 24
    local textWidth = tooltipWidth - padding * 2

    local _, wrapped = font:getWrap(description, textWidth)
    local statsCount = 5
    local descriptionY = 32 + statsCount * lineHeight + 4
    local tooltipHeight = descriptionY + #wrapped * font:getHeight() + padding

    local _, mouseY = love.mouse.getPosition()
    local tooltipY = clamp(mouseY + 12, panelY + 8, panelY + panelHeight - tooltipHeight - 8)

    love.graphics.setColor(0.08, 0.10, 0.15, 0.97)
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 7, 7)
    love.graphics.setColor(0.85, 0.88, 0.94)
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 7, 7)

    local textX = tooltipX + padding
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(crafting.titleFont)
    love.graphics.print(item.name, textX, tooltipY + 8)

    love.graphics.setFont(font)
    local stats = {
        "ID: " .. itemId,
        "Owned: " .. crafting.inventory:count(itemId),
        "Type: " .. tostring(item.type),
        "Rarity: " .. tostring(item.rarity),
        "Weight: " .. tostring(item.weight),
    }
    for i, line in ipairs(stats) do
        love.graphics.print(line, textX, tooltipY + 32 + (i - 1) * lineHeight)
    end
    love.graphics.printf(description, textX, tooltipY + descriptionY, textWidth, "left")
end

function Crafting:draw(isMorning)
    if not isMorning then return end

    local bx, by, bw, bh = buttonBounds()
    love.graphics.setColor(0.13, 0.16, 0.22)
    love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.buttonFont)
    love.graphics.printf("Crafting", bx, by + (bh - self.buttonFont:getHeight()) / 2, bw, "center")

    if not self.open then return end

    local px, py, pw, ph = panelBounds()
    local lx, ly, lw, lh, contentHeight, maxScroll = listLayout(px, py, pw, ph)
    self.scroll = clamp(self.scroll, 0, maxScroll)
    local mouseX, mouseY = love.mouse.getPosition()
    local hovered = hoveredRecipe(mouseX, mouseY, lx, ly, lw, lh, self.scroll)

    love.graphics.setColor(0.08, 0.10, 0.15, 0.86)
    love.graphics.rectangle("fill", px, py, pw, ph, 8, 8)
    love.graphics.setColor(0.9, 0.92, 0.96)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("Recipes", px + 12, py + 12)

    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.setScissor(lx, ly, lw, lh)
    for index, recipe in ipairs(recipes) do
        local cardY = ly + (index - 1) * cardStep - self.scroll
        if cardY + cardHeight >= ly and cardY <= ly + lh then
            drawCard(self, recipe, lx, cardY, lw)
        end
    end
    if sx then
        love.graphics.setScissor(sx, sy, sw, sh)
    else
        love.graphics.setScissor()
    end

    if maxScroll > 0 then
        local trackX = px + pw - 12
        local thumbHeight = math.max(20, lh * lh / contentHeight)
        local thumbY = ly + self.scroll / maxScroll * (lh - thumbHeight)
        love.graphics.setColor(0.18, 0.22, 0.30)
        love.graphics.rectangle("fill", trackX, ly, 4, lh, 2, 2)
        love.graphics.setColor(0.65, 0.72, 0.82)
        love.graphics.rectangle("fill", trackX, thumbY, 4, thumbHeight, 2, 2)
    end

    if hovered then
        drawTooltip(self, hovered.result.id, px, py, pw, ph)
    end
end

return Crafting
