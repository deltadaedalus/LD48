local wiringEntity = require "wiringEntity"
local sprite = require "sprite"
local playerTool = {}
playerTool.__index = playerTool

playerTool.setupSound = love.audio.newSource("sounds/setup.wav", "static")

function playerTool.new()
    local self = setmetatable({}, playerTool)

    self.toolRefresh = 0

    return self
end

function playerTool:use(player, mousePos) end

function playerTool:cancel(player, mousePos) end

function playerTool:update(player, dt) end

function playerTool:draw(player) end

--
--Pickaxe--
--
playerTool.pickaxe = playerTool.new()
playerTool.pickaxe.toolImage = love.graphics.newImage("images/pickaxeTool.png")
playerTool.pickaxe.sprite = sprite.new(love.graphics.newImage("images/pickaxe.png"), 0, 1/95, 1/95, 128, 280)
playerTool.pickaxe.pickPeriod = 0.5
playerTool.pickaxe.icon = love.graphics.newImage("images/pickIcon.png")

function playerTool.pickaxe:use( player, mousePos )
    if (t > self.toolRefresh) then
        local playerPos = player:getPosition()
        local dir = (mousePos - playerPos)
        local digDist = 5
        local hit, digPos = levelTerrain:rayCast(playerPos, dir, 0.5, digDist)
        digPos = hit and digPos or (playerPos + (dir:unit() * 5))
        levelTerrain:paint(self.toolImage, digPos.x, digPos.y, self.toolImage:getWidth()/2, self.toolImage:getHeight()/2, 0.1)
        levelResources:dig(digPos, self.toolImage:getWidth() + self.toolImage:getHeight())
        self.toolRefresh = t + self.pickPeriod
    end
end

function playerTool.pickaxe:update(player, dt)
    
end

function playerTool.pickaxe:draw(player)
    local baseAngle = -math.pi/3
    local followThrough = math.pi/2

    local position = player:getPosition()
    local swingTime = t - self.toolRefresh + self.pickPeriod
    local angle =  baseAngle + (
        swingTime < 0.1 and (swingTime * 10)^2 * followThrough
        or swingTime < 0.4 and ((0.4 - swingTime) * 10/3)^2 * followThrough
        or 0)

    local pos = position + vector.new(1.5 * player.dir, 0.5)
    playerTool.pickaxe.sprite:draw(pos.x, pos.y, angle * player.dir, player.dir, 1)
end

--
--Laser--
--
playerTool.laser = playerTool.new()
playerTool.laser.toolImage = love.graphics.newImage("images/laserTool.png")
playerTool.laser.sprite = sprite.new(love.graphics.newImage("images/lasergun.png"), 0, 1/95, 1/95, 200, 90)
playerTool.laser.firePeriod = 0.3
playerTool.laser.icon = love.graphics.newImage("images/laserIcon.png")
playerTool.laser.sound = love.audio.newSource("sounds/laser.wav", "static")

function playerTool.laser:use( player, mousePos )
    if (t > self.toolRefresh and player.energy > 8) then
        local playerPos = player:getPosition()
        local dir = (mousePos - playerPos)
        local fireDist = 100
        local hit, digPos = levelTerrain:rayCast(playerPos, dir, 0.5, fireDist)
        
        player:addEnergy(-8)
        self.sound:clone():play()
        self.toolRefresh = t + self.firePeriod
        if (hit) then
            levelTerrain:paint(self.toolImage, digPos.x, digPos.y, self.toolImage:getWidth()/2, self.toolImage:getHeight()/2, 0.005)
            levelResources:dig(digPos, self.toolImage:getWidth() + self.toolImage:getHeight())
        end

        local startPos = playerPos + vector.new(1 * player.dir, 0)
        self:laserCritters(startPos, digPos)

        self.lastStart = startPos
        self.lastEnd = digPos
    end
end

function playerTool.laser:update(player, dt)
    
end

function playerTool.laser:laserCritters(startPos, endPos)
    local dir = endPos - startPos
    for i, c in ipairs(critter.activeCritters) do
        local pos = vector.new(c.collider:getPosition())
        local dotFwd = dir:dot(endPos - pos)
        local dotBwd = dir:dot(startPos - pos)
        if (dotFwd > 0) and (dotBwd < 0) then
            local rej = (endPos - pos):rej(dir)
            print(rej)
            if (rej:mag() < 1) then
                c:murder()
            end
        end
    end
end

function playerTool.laser:draw(player)
    local mousePos = screenToWorld(vector.new(love.mouse.getPosition()));
    local position = player:getPosition()
    local baseAngle = position:angleTo(mousePos)
    local followThrough = -math.pi/6

    local swingTime = t - self.toolRefresh + self.firePeriod
    local angle =  baseAngle + (
        swingTime < 0.1 and (swingTime * 10)^2 * followThrough
        or swingTime < 0.3 and ((0.3 - swingTime) * 10/3)^2 * followThrough
        or 0) * player.dir

    local pos = position + vector.new(1 * player.dir, 0)
    playerTool.laser.sprite:draw(pos.x, pos.y, angle + (player.dir > 0 and 0 or math.pi), player.dir, 1)

    if (self.lastStart ~= nil and swingTime < 0.2) then
        local laserVal = (0.2 - swingTime) * 5
        local startScoot = self.lastStart + (self.lastEnd - self.lastStart):unit() * 3

        love.graphics.setColor(1, 1, 0, 0.5 * laserVal * laserVal)
        love.graphics.setLineWidth(0.4 + 1 - laserVal)
        love.graphics.line(startScoot.x, startScoot.y, self.lastEnd.x, self.lastEnd.y)
        love.graphics.setColor(1, 1, 0, 0.5 * laserVal)
        love.graphics.circle("fill", self.lastEnd.x, self.lastEnd.y, laserVal * 3)
        
        love.graphics.setColor(1, 1, 1, laserVal * laserVal)
        love.graphics.setLineWidth(0.2 + (1 - laserVal)/2)
        love.graphics.line(startScoot.x, startScoot.y, self.lastEnd.x, self.lastEnd.y)
        love.graphics.setColor(1, 1, 1, 0.25 * laserVal)
        love.graphics.circle("fill", self.lastEnd.x, self.lastEnd.y, laserVal * laserVal * 2.5)
    end
end

--
--Construction--
--
local constructible = require("constructible")
playerTool.construction = playerTool.new()
playerTool.construction.constructibles = {
    shelter = constructible.new(
        sprite.new(love.graphics.newImage("images/testCube.png"), 0, 1/16, 1/16, 16, 16), 
        {-1, -1, -1, 1, 1, -1, 1, 1}, 
        false),

    scaffold = constructible.new(
        sprite.new(love.graphics.newImage("images/scaffold.png"), 0, 1/16, 1/16, 16, 16), 
        {-1, -1, -1, 1, 1, -1, 1, 1}, 
        true),

    hab = constructible.new(
        sprite.new(love.graphics.newImage("images/shelter.png"), 0, 1/16, 1/16, 16, 16), 
        {-1, -1, -1, 1, 1, -1, 1, 1}, 
        true)
}
playerTool.construction.currentConstructible = playerTool.construction.constructibles.shelter
playerTool.construction.icon = love.graphics.newImage("images/testCube.png")

function playerTool.construction:use( player, mousePos )
    if (t > self.toolRefresh) then
        if (self.currentConstructible:canConstruct(world, mousePos)) then
            self.currentConstructible:construct(world, mousePos)
            self.toolRefresh = t + 0.5
        end
    end
end

function playerTool.construction:update(player, dt)
    
end

function playerTool.construction:draw(player)
    local mousePos = screenToWorld(vector.new(love.mouse.getPosition()));
    self.currentConstructible:drawGhost(mousePos)
end

--
--Wiring--
--
playerTool.wiring = playerTool.new()
playerTool.wiring.maxLinkingDist = 25

playerTool.wiring.hoveredEntity = nil
playerTool.wiring.linkingFromEntity = nil
playerTool.wiring.icon = love.graphics.newImage("images/wiringNodeIcon.png")

function playerTool.wiring:use( player, mousePos )
    if (t > self.toolRefresh) then
        local playerPos = player:getPosition()
        if (self.linkingFromEntity ~= nil and mousePos:dist(self.linkingFromEntity.position) <= self.maxLinkingDist) then
            local indexOfCopper = self:indexOfCopperInPlayerInventory()
            if indexOfCopper then
                local dir = mousePos - self.linkingFromEntity.position
                local hit, hitPos = levelTerrain:rayCast(self.linkingFromEntity.position, dir, 0.5, math.huge)
                if (not hit) or (hitPos:dist(self.linkingFromEntity.position) > hitPos:dist(mousePos)) then
                    self.linkingFromEntity = wiringEntity.new(mousePos, self.linkingFromEntity)
                    self.setupSound:play()
                    table.remove(player.heldItems, indexOfCopper)
                end
            end
        elseif(self.hoveredEntity ~= nil) then
            self.linkingFromEntity = self.hoveredEntity
        elseif(#wiringEntity.all == 0) then
            self.linkingFromEntity = wiringEntity.new(mousePos, nil)  --Delete this, it's just for debug to make it easier to create the first
        end
        self.toolRefresh = t + 0.5
    end
end

function playerTool.wiring:indexOfCopperInPlayerInventory()
    for i, v in ipairs(player.heldItems) do
        if v == "copper" then
            return i
        end
    end
    return nil
end

function playerTool.wiring:cancel( player, mousePos)
    self.linkingFromEntity = nil
end

function playerTool.wiring:update(player, dt)
    local mousePos = screenToWorld(vector.new(love.mouse.getPosition()));
    self.hoveredEntity = wiringEntity.nearestWiringEntity(mousePos, 2)
end

function playerTool.wiring:draw(player)
    local mousePos = screenToWorld(vector.new(love.mouse.getPosition()));
    if (self.linkingFromEntity ~= nil) then
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setLineWidth(0.25)
        love.graphics.circle("line", self.linkingFromEntity.position.x, self.linkingFromEntity.position.y, 1)
        if (self.linkingFromEntity.position:dist(mousePos) <= self.maxLinkingDist and self:indexOfCopperInPlayerInventory() ~= nil) then 
            love.graphics.line(self.linkingFromEntity.position.x, self.linkingFromEntity.position.y, mousePos.x, mousePos.y)
        end
    elseif (self.hoveredEntity ~= nil) then
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.setLineWidth(0.25)
        love.graphics.circle("line", self.hoveredEntity.position.x, self.hoveredEntity.position.y, 1)
    end
end

return playerTool