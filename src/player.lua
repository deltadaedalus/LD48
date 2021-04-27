bf = require "breezefield"
local entity = require "entity"
local collider = require "breezefield.collider"
local tools = require "playertool"
local sprite = require "sprite"

local Player = setmetatable({}, entity)
Player.__index = Player

Player.jumpImpulse = -0.42
Player.moveSpeed = 16
Player.moveForce = 0.25
Player.toolList = {tools.pickaxe, tools.laser, tools.wiring, tools.construction}
Player.toolIndex = 1
Player.standingImage = love.graphics.newImage("images/player_fancy.png")
Player.standingSprite = sprite.new(Player.standingImage, 0, 1/95, 1/95, 128, 190)
Player.plugSound = love.audio.newSource("sounds/plug.wav", "static")
Player.unplugSound = love.audio.newSource("sounds/unplug.wav", "static")
Player.inventorySize = 5
Player.maxEnergy = 100
Player.dischargeRate = 2
Player.rechargeRate = 20

function Player.new(world, terrain)
    local self = setmetatable(entity.new(), Player)

    local position = vector.new(178, 45)
    self.collider = bf.Collider.new(world, "Polygon", 
        1.2, 1.8, 
        1, 2, 
        0, 2,  
        -1, 2, 
        -1.2, 1.8, 
        -1.2, -1.4, 
        0, -1.8, 
        1.2, -1.4)
    self.collider:setFixedRotation(true)
    self.collider:setPosition(position.x, position.y)
    self.collider:setFilterData(1, 65535, -1)
    self.collider:setSleepingAllowed(false)
    terrain:addCollider(world, self.collider, 15, true)
    table.insert(entity.acceptsInput, self)

    self.currentTool = self.toolList[self.toolIndex]
    self.energy = self.maxEnergy
    self.wireConnection = nil
    self.heldItems = {"copper", "copper", "copper"}
    self.spawn = self:getPosition()

    self.dir = 1
    return self
end

function Player:update(dt)
    self:move(dt)
    self:updateTools(dt)
    self:updateElectricity(dt)
    self:updateRads(dt)
end

function Player:move(dt)
    local mousePos = screenToWorld(vector.new(love.mouse.getPosition()));
    self.dir = mousePos.x > self:getPosition().x and 1 or -1
    
    local playerPosition = self:getPosition()
    local playerVelocity = vector.new(self.collider:getLinearVelocity())

    local intent = vector.new(0, 0)
    if love.keyboard.isDown('a') then intent.x = intent.x - 1 end
    if love.keyboard.isDown('d') then intent.x = intent.x + 1 end
    intent = intent == vector.origin and intent or intent:unit() * self.moveSpeed
    
    local xDelta = intent.x - playerVelocity.x
    self.collider:applyForce(self.moveForce * xDelta, 0)
end

function Player:updateTools(dt)
    local mousePos = screenToWorld(vector.new(love.mouse.getPosition()));
    self.currentTool:update(dt)
    if (love.mouse.isDown(1)) then
        self.currentTool:use(self, mousePos)
    end
end

function Player:updateElectricity(dt)
    local nearestEntity = wiringEntity.nearestWiringEntity(self:getPosition(), 15, true)

    if self.wireConnection == nil and nearestEntity ~= nil then
        self.plugSound:play()
    elseif self.wireConnection ~= nil and nearestEntity == nil then
        self.unplugSound:play()
    end

    self.wireConnection = nearestEntity

    if (self.wireConnection ~= nil) then
        self:addEnergy(self.rechargeRate * dt)
    else
        self:addEnergy(-self.dischargeRate * dt)
    end
end

function Player:addEnergy(amt)
    self.energy = math.min(self.energy + amt, self.maxEnergy)
    if (self.energy <= 0) then
        self:kill()
    end
end

function Player:isStandingOnSomething()
    local contacts = self.collider:getContacts()
    local pos = self:getPosition()
    for i, c in ipairs(contacts) do
        local x1, y1, x2, y2 = c:getPositions()

        if (y1 ~= nil and y1 > pos.y + 1.5) then return true end
        if (y2 ~= nil and y2 > pos.y + 1.5) then return true end
    end
    return false
end

Player.radBase = 10
function Player:updateRads(dt)
    local pos = self:getPosition()
    local radioactivity = self.radBase/((radDepth - pos.y)^2)
    for i = 1, 10 do
        if (math.random() < radioactivity) then
            self:tickRad()
        end
    end
end

function Player:tickRad()
    self.energy = self.energy - .1
    ui.tickGeigerCounter()
end

function Player:kill()
    self.collider:setPosition(self.spawn.x, self.spawn.y)
    self.energy = self.maxEnergy / 4
    self.heldItems = {}
end

function Player:getPosition()
    local playerPosition = vector.new(self.collider:getX(), self.collider:getY())
    return playerPosition
end

function Player:draw()
    --love.graphics.setColor(1, 1, 1, 0.2)
    --love.graphics.circle("fill", self.collider:getX(), self.collider:getY(), 2)

    self:drawElectricity()

    love.graphics.setColor(1, 1, 1, 1)
    self.standingSprite:draw(self.collider:getX(), self.collider:getY(), 0, self.dir, 1)

    self.currentTool:draw(self)
end

function Player:renderLighting()
    love.graphics.setColor(1, 1, 1, 1)
    local scale = 1.8 + 0.2 * (love.math.noise(t) ^ 0.25)
    love.graphics.draw(wiringEntity.lightingImage, self.collider:getX(), self.collider:getY(), 0, scale, scale, 20, 20)
end

function Player:drawElectricity()
    if (self.wireConnection ~= nil) then
        love.graphics.setColor(0.1, 0.1, 0.1, 1)
        love.graphics.setLineWidth(0.25)
        self.wireConnection.drawDroopyLine(self:getPosition(), self.wireConnection.position, 1)
    end
end

function Player:mousepressed( x, y, button, istouch, presses )
    mousePos = screenToWorld(vector.new(x, y))
    if (button == 1) then
        self.currentTool:use(self, mousePos)
    else
        self.currentTool:cancel(self, mousePos)
    end
end

function Player:keypressed( key, scancode, isrepeat )
    if (key == 'space') then
        local playerPosition = vector.new(self.collider:getX(), self.collider:getY())
        local feetPosition = playerPosition + vector.new(0, 4)

        local onGround = levelTerrain:valueAt(feetPosition) > 0.5 or self:isStandingOnSomething()

        if onGround then
            self.collider:applyLinearImpulse(0, self.jumpImpulse)
        end
    end

    if (key == 'q') then
        player.toolIndex = player.toolIndex % #player.toolList + 1
        player.currentTool = player.toolList[player.toolIndex]
    end
    if (key == 'e') then
        player.toolIndex = (player.toolIndex - 2) % #player.toolList + 1
        player.currentTool = player.toolList[player.toolIndex]
    end

    if (tonumber(key)) then
        local index = tonumber(key)
        if (player.toolList[index]) then
            player.toolIndex = index
            player.currentTool = player.toolList[player.toolIndex]
        end
    end
end

return Player