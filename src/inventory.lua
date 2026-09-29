local items = require("src.items")

local Inventory = {}
Inventory.__index = Inventory

local rowHeight = 38
local rowSpacing = 7
local rowStep = rowHeight + rowSpacing

local function inside(x, y, bx, by, bw, bh)
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, maximum))
end

local function buttonBounds()
    local _, h = love.graphics.getDimensions()
    return 20, h - 54, 100, 38
end

local function panelBounds()
    local width, height = love.graphics.getDimensions()
    return 20, 70, math.min(350, math.floor(width * 0.48)), height - 140
end

local function listLayout(inventory, panelX, panelY, panelWidth, panelHeight)
    local listX = panelX + 12
    local listY = panelY + 48
    local listHeight = panelHeight - 60
    local contentHeight = math.max(0, #inventory.slots * rowStep - rowSpacing)
    local maxScroll = math.max(0, contentHeight - listHeight)
    local listWidth = panelWidth - (maxScroll > 0 and 36 or 24)
    return listX, listY, listWidth, listHeight, contentHeight, maxScroll
end

function Inventory.new()
    return setmetatable({
        open = false,
        scroll = 0,
        slots = {
            { id = "wood",     quantity = 5 },
            { id = "iron_bar", quantity = 4 },
            { id = "stone",    quantity = 3 },
            { id = "fiber",    quantity = 8 },
        },
    }, Inventory)
end

function Inventory:load()
    self.titleFont = love.graphics.newFont(16)
    self.rowFont = love.graphics.newFont(14)
    self.tooltipFont = love.graphics.newFont(12)
end

function Inventory.add(inventory, id, quantity)
    if not items[id] or type(quantity) ~= "number" or quantity <= 0 or quantity % 1 ~= 0 then
        return false
    end

    for index, slot in ipairs(inventory.slots) do
        if slot.id == id then
            slot.quantity = slot.quantity + quantity
            inventory.scroll = (index - 1) * rowStep
            return true
        end
    end

    table.insert(inventory.slots, { id = id, quantity = quantity })
    inventory.scroll = (#inventory.slots - 1) * rowStep
    return true
end

function Inventory.count(inventory, id)
    local total = 0
    for _, slot in ipairs(inventory.slots) do
        if slot.id == id then
            total = total + slot.quantity
        end
    end
    return total
end

function Inventory.remove(inventory, id, quantity)
    if type(quantity) ~= "number" or quantity <= 0 or quantity % 1 ~= 0
        or Inventory.count(inventory, id) < quantity then
        return false
    end

    for index = #inventory.slots, 1, -1 do
        local slot = inventory.slots[index]
        if slot.id == id then
            local taken = math.min(slot.quantity, quantity)
            slot.quantity = slot.quantity - taken
            quantity = quantity - taken
            if slot.quantity == 0 then
                table.remove(inventory.slots, index)
            end
            if quantity == 0 then return true end
        end
    end
end

function Inventory:mousepressed(x, y, button)
    if button ~= 1 then return false end

    local bx, by, bw, bh = buttonBounds()
    if inside(x, y, bx, by, bw, bh) then
        self.open = not self.open
        return true
    end

    if self.open then
        local px, py, pw, ph = panelBounds()
        if inside(x, y, px, py, pw, ph) then
            return true
        end
    end

    return false
end

function Inventory:wheelmoved(_, y)
    if not self.open then return end

    local mouseX, mouseY = love.mouse.getPosition()
    local px, py, pw, ph = panelBounds()
    if not inside(mouseX, mouseY, px, py, pw, ph) then return end

    local _, _, _, _, _, maxScroll = listLayout(self, px, py, pw, ph)
    self.scroll = clamp(self.scroll - y * rowStep, 0, maxScroll)
end

local function hoveredSlot(inventory, mouseX, mouseY, listX, listY, listWidth, listHeight)
    if not inside(mouseX, mouseY, listX, listY, listWidth, listHeight) then
        return nil
    end

    for index, slot in ipairs(inventory.slots) do
        local rowY = listY + (index - 1) * rowStep - inventory.scroll
        if inside(mouseX, mouseY, listX, rowY, listWidth, rowHeight) then
            return slot
        end
    end
end

function Inventory:slotAt(x, y)
    if not self.open then return nil end
    local px, py, pw, ph = panelBounds()
    local lx, ly, lw, lh, _, maxScroll = listLayout(self, px, py, pw, ph)
    self.scroll = clamp(self.scroll, 0, maxScroll)
    return hoveredSlot(self, x, y, lx, ly, lw, lh)
end

local function drawTooltip(inventory, slot, panelX, panelY, panelWidth, panelHeight)
    local item = items[slot.id]
    local tooltipX = panelX + 12
    local tooltipWidth = panelWidth - 24
    local _, descriptionLines = inventory.tooltipFont:getWrap(item.description, tooltipWidth - 20)
    local tooltipHeight = 148 + #descriptionLines * inventory.tooltipFont:getHeight()
    local _, mouseY = love.mouse.getPosition()
    local tooltipY = clamp(mouseY + 12, panelY + 8, panelY + panelHeight - tooltipHeight - 8)

    love.graphics.setColor(0.08, 0.10, 0.15, 0.97)
    love.graphics.rectangle("fill", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 7, 7)
    love.graphics.setColor(0.85, 0.88, 0.94)
    love.graphics.rectangle("line", tooltipX, tooltipY, tooltipWidth, tooltipHeight, 7, 7)

    local textX = tooltipX + 10
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(inventory.titleFont)
    love.graphics.print(item.name, textX, tooltipY + 8)
    love.graphics.setFont(inventory.tooltipFont)
    love.graphics.print("ID: " .. slot.id, textX, tooltipY + 32)
    love.graphics.print("Quantity: " .. slot.quantity, textX, tooltipY + 48)
    love.graphics.print("Type: " .. item.type, textX, tooltipY + 64)
    love.graphics.print("Rarity: " .. item.rarity, textX, tooltipY + 80)
    love.graphics.print("Weight: " .. item.weight, textX, tooltipY + 96)
    love.graphics.print("Sell price: " .. item.sellPrice .. " coins", textX, tooltipY + 112)
    love.graphics.printf(item.description, textX, tooltipY + 132, tooltipWidth - 20, "left")
end

function Inventory:draw()
    local bx, by, bw, bh = buttonBounds()
    love.graphics.setColor(0.13, 0.16, 0.22)
    love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.rowFont)
    love.graphics.printf("Inventory", bx, by + (bh - self.rowFont:getHeight()) / 2, bw, "center")

    if not self.open then return end

    local px, py, pw, ph = panelBounds()
    local lx, ly, lw, lh, contentHeight, maxScroll = listLayout(self, px, py, pw, ph)
    self.scroll = clamp(self.scroll, 0, maxScroll)

    love.graphics.setColor(0.08, 0.10, 0.15, 0.86)
    love.graphics.rectangle("fill", px, py, pw, ph, 8, 8)
    love.graphics.setColor(0.9, 0.92, 0.96)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("Inventory", px + 12, py + 12)

    local mouseX, mouseY = love.mouse.getPosition()
    local hovered = hoveredSlot(self, mouseX, mouseY, lx, ly, lw, lh)
    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.setScissor(lx, ly, lw, lh)
    for index, slot in ipairs(self.slots) do
        local rowY = ly + (index - 1) * rowStep - self.scroll
        if rowY + rowHeight >= ly and rowY <= ly + lh then
            love.graphics.setColor(slot == hovered and 0.35 or 0.21, slot == hovered and 0.43 or 0.26,
                slot == hovered and 0.57 or 0.35)
            love.graphics.rectangle("fill", lx, rowY, lw, rowHeight, 5, 5)
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(self.rowFont)
            love.graphics.print(items[slot.id].name, lx + 10, rowY + 10)
            love.graphics.printf("x" .. slot.quantity, lx + 10, rowY + 10, lw - 20, "right")
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
        drawTooltip(self, hovered, px, py, pw, ph)
    end
end

return Inventory
