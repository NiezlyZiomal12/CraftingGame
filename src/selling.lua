local Inventory = require("src.inventory")
local items = require("src.items")

local Selling = {}
Selling.__index = Selling

local rowHeight = 44
local rowStep = 50

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
    return width - panelWidth - 20, 70, panelWidth, height - 140
end

local function listLayout(selling, px, py, pw, ph)
    local lx, ly = px + 12, py + 62
    local lh = ph - 132
    local contentHeight = math.max(0, #selling.container.slots * rowStep - (rowStep - rowHeight))
    local maxScroll = math.max(0, contentHeight - lh)
    local lw = pw - (maxScroll > 0 and 36 or 24)
    return lx, ly, lw, lh, contentHeight, maxScroll
end

function Selling.new(inventory, gameState)
    return setmetatable({
        inventory = inventory,
        gameState = gameState,
        container = { slots = {}, scroll = 0 },
        coins = 0,
        open = false,
        scroll = 0,
    }, Selling)
end

function Selling:load()
    self.titleFont = love.graphics.newFont(16)
    self.rowFont = love.graphics.newFont(13)
    self.buttonFont = love.graphics.newFont(14)
end

function Selling:put(id)
    if not self.open or not items[id] or not self.inventory:remove(id, 1) then
        return false
    end
    Inventory.add(self.container, id, 1)
    self.scroll = (#self.container.slots - 1) * rowStep
    return true
end

function Selling:takeBack(id)
    if not Inventory.remove(self.container, id, 1) then return false end
    self.inventory:add(id, 1)
    return true
end

function Selling:total()
    local total = 0
    for _, slot in ipairs(self.container.slots) do
        total = total + slot.quantity * items[slot.id].sellPrice
    end
    return total
end

function Selling:sellAll()
    local total = self:total()
    if total == 0 then return false end
    self.coins = self.coins + total
    self.container.slots = {}
    self.scroll = 0
    return true
end

function Selling:leaveAfternoon()
    self.gameState.coins = self.gameState.coins + self.coins
    self.coins = 0
    for _, slot in ipairs(self.container.slots) do
        self.inventory:add(slot.id, slot.quantity)
    end
    self.container.slots = {}
    self.scroll = 0
    self.open = false
end

function Selling:mousepressed(x, y, button, isAfternoon)
    if button ~= 1 or not isAfternoon then return false end

    local bx, by, bw, bh = buttonBounds()
    if inside(x, y, bx, by, bw, bh) then
        self.open = not self.open
        if self.open then self.inventory.open = true end
        return true
    end

    if not self.open then return false end

    local px, py, pw, ph = panelBounds()
    if not inside(x, y, px, py, pw, ph) then return false end

    local sellX, sellY, sellWidth = px + 12, py + ph - 38, pw - 24
    if inside(x, y, sellX, sellY, sellWidth, 28) then
        self:sellAll()
        return true
    end

    local lx, ly, lw, lh, _, maxScroll = listLayout(self, px, py, pw, ph)
    self.scroll = clamp(self.scroll, 0, maxScroll)
    if inside(x, y, lx, ly, lw, lh) then
        for index, slot in ipairs(self.container.slots) do
            local rowY = ly + (index - 1) * rowStep - self.scroll
            if inside(x, y, lx, rowY, lw, rowHeight) then
                self:takeBack(slot.id)
                break
            end
        end
    end

    return true
end

function Selling:wheelmoved(_, y, isAfternoon)
    if not isAfternoon or not self.open then return end

    local mouseX, mouseY = love.mouse.getPosition()
    local px, py, pw, ph = panelBounds()
    if not inside(mouseX, mouseY, px, py, pw, ph) then return end

    local _, _, _, _, _, maxScroll = listLayout(self, px, py, pw, ph)
    self.scroll = clamp(self.scroll - y * rowStep, 0, maxScroll)
end

function Selling:draw(isAfternoon)
    if not isAfternoon then return end

    local bx, by, bw, bh = buttonBounds()
    love.graphics.setColor(0.13, 0.16, 0.22)
    love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.buttonFont)
    love.graphics.printf("Selling", bx, by + (bh - self.buttonFont:getHeight()) / 2, bw, "center")

    if not self.open then return end

    local px, py, pw, ph = panelBounds()
    local lx, ly, lw, lh, contentHeight, maxScroll = listLayout(self, px, py, pw, ph)
    self.scroll = clamp(self.scroll, 0, maxScroll)

    love.graphics.setColor(0.08, 0.10, 0.15, 0.86)
    love.graphics.rectangle("fill", px, py, pw, ph, 8, 8)
    love.graphics.setColor(0.9, 0.92, 0.96)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("Sell items", px + 12, py + 10)

    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.setScissor(lx, ly, lw, lh)
    if #self.container.slots == 0 then
        love.graphics.setColor(0.72, 0.76, 0.82)
        love.graphics.setFont(self.rowFont)
        love.graphics.print("No items selected", lx + 6, ly + 8)
    end
    for index, slot in ipairs(self.container.slots) do
        local rowY = ly + (index - 1) * rowStep - self.scroll
        if rowY + rowHeight >= ly and rowY <= ly + lh then
            local item = items[slot.id]
            love.graphics.setColor(0.21, 0.26, 0.35)
            love.graphics.rectangle("fill", lx, rowY, lw, rowHeight, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.rowFont)
            love.graphics.print(item.name, lx + 8, rowY + 4)
            love.graphics.printf("x" .. slot.quantity, lx + 8, rowY + 4, lw - 16, "right")
            love.graphics.setColor(0.78, 0.86, 0.70)
            love.graphics.print(item.sellPrice .. " coins each", lx + 8, rowY + 23)
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

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.rowFont)
    love.graphics.print("Today: " .. self.coins .. "  |  Sale: " .. self:total(), px + 12, py + ph - 62)

    local sellX, sellY, sellWidth = px + 12, py + ph - 38, pw - 24
    if self:total() > 0 then
        love.graphics.setColor(0.25, 0.49, 0.34)
    else
        love.graphics.setColor(0.38, 0.39, 0.42)
    end
    love.graphics.rectangle("fill", sellX, sellY, sellWidth, 28, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.buttonFont)
    love.graphics.printf("Sell all", sellX, sellY + 5, sellWidth, "center")
end

return Selling
