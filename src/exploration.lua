local items = require("src.items")
local locations = require("src.locations")

local Exploration = {}
Exploration.__index = Exploration

local contentHeight = 270

local function inside(x, y, bx, by, bw, bh)
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(value, maximum))
end

local function panelBounds()
    local width, height = love.graphics.getDimensions()
    local panelWidth = math.min(350, math.floor(width * 0.42))
    return width - panelWidth - 20, 70, panelWidth, height - 140
end

local function contentLayout(px, py, pw, ph)
    local x, y = px + 12, py + 38
    local height = ph - 84
    local maxScroll = math.max(0, contentHeight - height)
    local width = pw - (maxScroll > 0 and 36 or 24)
    return x, y, width, height, maxScroll
end

local function optionBounds(x, y, width, index)
    local optionWidth = math.floor((width - 8) / 3)
    return x + (index - 1) * (optionWidth + 4), y, optionWidth, 22
end

function Exploration.new(inventory, loadout)
    return setmetatable({
        inventory = inventory,
        loadout = loadout,
        location = 1,
        tier = 1,
        scroll = 0,
        attempted = false,
        success = nil,
        result = nil,
        lastPower = nil,
        lastChance = nil,
        lastLooting = nil,
    }, Exploration)
end

function Exploration:load()
    self.titleFont = love.graphics.newFont(16)
    self.buttonFont = love.graphics.newFont(13)
    self.smallFont = love.graphics.newFont(12)
end

function Exploration:beginNight()
    self.location = 1
    self.tier = 1
    self.scroll = 0
    self.attempted = false
    self.success = nil
    self.result = nil
    self.lastPower = nil
    self.lastChance = nil
    self.lastLooting = nil
end

function Exploration:leaveNight()
    if not self.attempted then
        self.loadout:finishExpedition(true)
    end
end

function Exploration:selectedTier()
    return locations[self.location].tiers[self.tier]
end

function Exploration:survivalChance(survivability)
    return clamp(self:selectedTier().baseSurvival + survivability * 0.035, 0.05, 0.95)
end

function Exploration:rewards(looting)
    local rewards = {}
    for index, reward in ipairs(self:selectedTier().loot) do
        rewards[index] = {
            id = reward.id,
            quantity = reward.quantity + (index == 1 and math.floor(looting / 2) or 0),
        }
    end
    return rewards
end

function Exploration:rewardText(looting)
    local names = {}
    for _, reward in ipairs(self:rewards(looting)) do
        names[#names + 1] = reward.quantity .. " " .. items[reward.id].name
    end
    return table.concat(names, ", ")
end

function Exploration:attempt()
    if self.attempted then return false end

    local power, survivability, looting = self.loadout:totals()
    if power < self:selectedTier().requiredPower then return false end

    local chance = self:survivalChance(survivability)
    self.lastPower = power
    self.lastChance = chance
    self.lastLooting = looting
    self.attempted = true

    local success = love.math.random() < chance
    self.success = success
    if success then
        self.loadout:finishExpedition(true)
        for _, reward in ipairs(self:rewards(looting)) do
            self.inventory:add(reward.id, reward.quantity)
        end
        self.result = "Success! Loot added to Inventory. Gear returned."
    else
        self.loadout:finishExpedition(false)
        self.result = "Expedition failed. No loot; loadout lost."
    end
    self.scroll = contentHeight
    return true
end

function Exploration:mousepressed(x, y, button, isNight)
    if button ~= 1 or not isNight then return false end

    local px, py, pw, ph = panelBounds()
    if not inside(x, y, px, py, pw, ph) then return false end

    local actionX, actionY, actionWidth = px + 12, py + ph - 38, pw - 24
    if inside(x, y, actionX, actionY, actionWidth, 28) then
        self:attempt()
        return true
    end

    local cx, cy, cw, ch, maxScroll = contentLayout(px, py, pw, ph)
    self.scroll = clamp(self.scroll, 0, maxScroll)
    if not self.attempted and inside(x, y, cx, cy, cw, ch) then
        for index = 1, #locations do
            local bx, by, bw, bh = optionBounds(cx, cy + 17 - self.scroll, cw, index)
            if inside(x, y, bx, by, bw, bh) then
                self.location = index
                self.tier = 1
                return true
            end
        end
        for index = 1, #locations[self.location].tiers do
            local bx, by, bw, bh = optionBounds(cx, cy + 64 - self.scroll, cw, index)
            if inside(x, y, bx, by, bw, bh) then
                self.tier = index
                return true
            end
        end
    end
    return true
end

function Exploration:wheelmoved(_, y, isNight)
    if not isNight then return end
    local mouseX, mouseY = love.mouse.getPosition()
    local px, py, pw, ph = panelBounds()
    if not inside(mouseX, mouseY, px, py, pw, ph) then return end
    local _, _, _, _, maxScroll = contentLayout(px, py, pw, ph)
    self.scroll = clamp(self.scroll - y * 40, 0, maxScroll)
end

local function drawOption(exploration, x, y, width, label, selected)
    if selected then
        love.graphics.setColor(0.30, 0.49, 0.64)
    else
        love.graphics.setColor(0.21, 0.26, 0.35)
    end
    love.graphics.rectangle("fill", x, y, width, 22, 4, 4)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(exploration.buttonFont)
    love.graphics.printf(label, x, y + 3, width, "center")
end

function Exploration:draw(isNight)
    if not isNight then return end

    local px, py, pw, ph = panelBounds()
    local cx, cy, cw, ch, maxScroll = contentLayout(px, py, pw, ph)
    self.scroll = clamp(self.scroll, 0, maxScroll)

    love.graphics.setColor(0.08, 0.10, 0.15, 0.86)
    love.graphics.rectangle("fill", px, py, pw, ph, 8, 8)
    love.graphics.setColor(0.9, 0.92, 0.96)
    love.graphics.setFont(self.titleFont)
    love.graphics.print("Night exploration", px + 12, py + 9)

    local power, survivability, looting = self.loadout:totals()
    local chance = self:survivalChance(survivability)
    if self.attempted then
        power, looting, chance = self.lastPower, self.lastLooting, self.lastChance
    end

    local sx, sy, sw, sh = love.graphics.getScissor()
    love.graphics.setScissor(cx, cy, cw, ch)
    local contentY = cy - self.scroll
    love.graphics.setColor(0.85, 0.89, 0.95)
    love.graphics.setFont(self.smallFont)
    love.graphics.print("Location", cx, contentY)
    for index, location in ipairs(locations) do
        local bx, by, bw = optionBounds(cx, contentY + 17, cw, index)
        drawOption(self, bx, by, bw, location.name, index == self.location)
    end

    love.graphics.setColor(0.85, 0.89, 0.95)
    love.graphics.setFont(self.smallFont)
    love.graphics.print("Tier", cx, contentY + 47)
    for index = 1, #locations[self.location].tiers do
        local bx, by, bw = optionBounds(cx, contentY + 64, cw, index)
        drawOption(self, bx, by, bw, tostring(index), index == self.tier)
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.smallFont)
    love.graphics.print("Your power: " .. power, cx, contentY + 96)
    love.graphics.print("Recommended: " .. self:selectedTier().requiredPower, cx, contentY + 113)
    love.graphics.print("Survival: " .. math.floor(chance * 100 + 0.5) .. "%", cx, contentY + 130)
    love.graphics.print("Loot bonus: +" .. math.floor(looting / 2), cx, contentY + 147)
    love.graphics.print("Possible loot:", cx, contentY + 164)
    love.graphics.printf(self:rewardText(looting), cx, contentY + 181, cw, "left")
    if self.result then
        love.graphics.setColor(self.success and 0.65 or 1, self.success and 0.95 or 0.62, 0.68)
        love.graphics.printf(self.result, cx, contentY + 225, cw, "left")
    end
    if sx then
        love.graphics.setScissor(sx, sy, sw, sh)
    else
        love.graphics.setScissor()
    end

    if maxScroll > 0 then
        local trackX = px + pw - 12
        local thumbHeight = math.max(20, ch * ch / contentHeight)
        local thumbY = cy + self.scroll / maxScroll * (ch - thumbHeight)
        love.graphics.setColor(0.18, 0.22, 0.30)
        love.graphics.rectangle("fill", trackX, cy, 4, ch, 2, 2)
        love.graphics.setColor(0.65, 0.72, 0.82)
        love.graphics.rectangle("fill", trackX, thumbY, 4, thumbHeight, 2, 2)
    end

    local actionX, actionY, actionWidth = px + 12, py + ph - 38, pw - 24
    local canEnter = power >= self:selectedTier().requiredPower and not self.attempted
    love.graphics.setColor(canEnter and 0.25 or 0.38, canEnter and 0.49 or 0.39, canEnter and 0.34 or 0.42)
    love.graphics.rectangle("fill", actionX, actionY, actionWidth, 28, 5, 5)
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(self.buttonFont)
    local label = self.attempted and "Done tonight" or (canEnter and "Explore" or "Need more power")
    love.graphics.printf(label, actionX, actionY + 6, actionWidth, "center")
end

return Exploration
