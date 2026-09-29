local items = require("src.items")
local itemTooltip = require("src.item_tooltip")

local Loadout = {}
Loadout.__index = Loadout

local slotDefinitions = {
    { key = "helmet", label = "Helmet" },
    { key = "chestplate", label = "Chestplate" },
    { key = "gloves", label = "Gloves" },
    { key = "leggings", label = "Leggings" },
    { key = "boots", label = "Boots" },
    { key = "weapon", label = "Weapon" },
    { key = "consumable1", label = "Consumable 1" },
    { key = "consumable2", label = "Consumable 2" },
    { key = "consumable3", label = "Consumable 3" },
    { key = "consumable4", label = "Consumable 4" },
    { key = "consumable5", label = "Consumable 5" },
}

local rowHeight = 46
local rowStep = 52

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

local function listLayout(px, py, pw, ph)
    local lx, ly = px + 12, py + 76
    local lh = ph - 88
    local contentHeight = #slotDefinitions * rowStep - (rowStep - rowHeight)
    local maxScroll = math.max(0, contentHeight - lh)
    local lw = pw - (maxScroll > 0 and 36 or 24)
    return lx, ly, lw, lh, contentHeight, maxScroll
end

function Loadout.new(inventory)
    local slots = {}
    for _, definition in ipairs(slotDefinitions) do
        slots[definition.key] = false
    end
    return setmetatable({ inventory = inventory, slots = slots, open = false, scroll = 0, message = nil }, Loadout)
end

function Loadout:load()
    self.titleFont = love.graphics.newFont(16)
    self.rowFont = love.graphics.newFont(13)
    self.buttonFont = love.graphics.newFont(14)
    self.smallFont = love.graphics.newFont(12)
end

function Loadout:close()
    self.open = false
    self.message = nil
end

function Loadout:finishExpedition(returnItems)
    for _, definition in ipairs(slotDefinitions) do
        local id = self.slots[definition.key]
        if id and returnItems then
            self.inventory:add(id, 1)
        end
        self.slots[definition.key] = false
    end
    self.scroll = 0
    self:close()
end

function Loadout:totals()
    local power, survival, loot = 1, 0, 0 -- Base power keeps Woods Tier 1 available after a failed expedition.
    for _, definition in ipairs(slotDefinitions) do
        local id = self.slots[definition.key]
        if id then
            local item = items[id]
            power = power + item.strongPower
            survival = survival + item.survivability
            loot = loot + item.looting
        end
    end
    return power, survival, loot
end

function Loadout:equip(id)
    if not self.open then return false end
    local item = items[id]
    if not item or not item.equipmentSlot then
        self.message = "Cannot equip this item"
        return false
    end

    local targetKey, targetIndex
    if item.equipmentSlot == "consumable" then
        for index = 7, #slotDefinitions do
            local key = slotDefinitions[index].key
            if not self.slots[key] then
                targetKey, targetIndex = key, index
                break
            end
        end
        if not targetKey then
            self.message = "Consumable slots are full"
            return false
        end
    else
        for index, definition in ipairs(slotDefinitions) do
            if definition.key == item.equipmentSlot then
                targetKey, targetIndex = definition.key, index
                break
            end
        end
        if not targetKey then return false end
    end

    if not self.inventory:remove(id, 1) then return false end
    local previous = self.slots[targetKey]
    self.slots[targetKey] = id
    if previous then self.inventory:add(previous, 1) end
    self.scroll = (targetIndex - 1) * rowStep
    self.message = nil
    return true
end

function Loadout:unequip(key)
    local id = self.slots[key]
    if not id then return false end
    self.slots[key] = false
    self.inventory:add(id, 1)
    self.message = nil
    return true
end

function Loadout:mousepressed(x, y, button, isEvening)
    if button ~= 1 or not isEvening then return false end

    local bx, by, bw, bh = buttonBounds()
    if inside(x, y, bx, by, bw, bh) then
        self.open = not self.open
        if self.open then self.inventory.open = true end
        return true
    end

    if not self.open then return false end
    local px, py, pw, ph = panelBounds()
    if not inside(x, y, px, py, pw, ph) then return false end

    local lx, ly, lw, lh, _, maxScroll = listLayout(px, py, pw, ph)
    self.scroll = clamp(self.scroll, 0, maxScroll)
    if inside(x, y, lx, ly, lw, lh) then
        for index, definition in ipairs(slotDefinitions) do
            local rowY = ly + (index - 1) * rowStep - self.scroll
            if inside(x, y, lx, rowY, lw, rowHeight) then
                self:unequip(definition.key)
                break
            end
        end
    end
    return true
end

function Loadout:wheelmoved(_, y, isEvening)
    if not isEvening or not self.open then return end
    local mouseX, mouseY = love.mouse.getPosition()
    local px, py, pw, ph = panelBounds()
    if not inside(mouseX, mouseY, px, py, pw, ph) then return end
    local _, _, _, _, _, maxScroll = listLayout(px, py, pw, ph)
    self.scroll = clamp(self.scroll - y * rowStep, 0, maxScroll)
end

function Loadout:draw(isEvening)
    if not isEvening then return end

    local bx, by, bw, bh = buttonBounds()
    love.graphics.setColor(0.13, 0.16, 0.22)
    love.graphics.rectangle("fill", bx, by, bw, bh, 6, 6)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.buttonFont)
    love.graphics.printf("Loadout", bx, by + (bh - self.buttonFont:getHeight()) / 2, bw, "center")

    if not self.open then return end
    local px, py, pw, ph = panelBounds()
    local lx, ly, lw, lh, contentHeight, maxScroll = listLayout(px, py, pw, ph)
    self.scroll = clamp(self.scroll, 0, maxScroll)

    love.graphics.setColor(0.08, 0.10, 0.15, 0.86)
    love.graphics.rectangle("fill", px, py, pw, ph, 8, 8)
    love.graphics.setColor(0.9, 0.92, 0.96)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("Night loadout", px + 12, py + 9)

    local power, survival, loot = self:totals()
    love.graphics.setFont(self.smallFont)
    love.graphics.print("Power " .. power .. "   Surv " .. survival .. "   Loot " .. loot, px + 12, py + 34)
    love.graphics.setColor(0.75, 0.81, 0.89)
    love.graphics.print(self.message or "Click Inventory item", px + 12, py + 53)

    local mouseX, mouseY = love.mouse.getPosition()
    local mouseInList = inside(mouseX, mouseY, lx, ly, lw, lh)
    local hoveredId
    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.setScissor(lx, ly, lw, lh)
    for index, definition in ipairs(slotDefinitions) do
        local rowY = ly + (index - 1) * rowStep - self.scroll
        if rowY + rowHeight >= ly and rowY <= ly + lh then
            local id = self.slots[definition.key]
            if id and mouseInList and inside(mouseX, mouseY, lx, rowY, lw, rowHeight) then
                hoveredId = id
            end
            love.graphics.setColor(0.21, 0.26, 0.35)
            love.graphics.rectangle("fill", lx, rowY, lw, rowHeight, 5, 5)
            love.graphics.setColor(0.78, 0.86, 0.95)
            love.graphics.setFont(self.rowFont)
            love.graphics.print(definition.label, lx + 8, rowY + 3)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(id and items[id].name or "Empty", lx + 8, rowY + 23)
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

    if hoveredId then
        itemTooltip.draw(hoveredId, 1, px, pw, self.titleFont, self.smallFont)
    end
end

return Loadout
