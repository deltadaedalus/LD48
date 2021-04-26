local entity = require "entity"
local critter = setmetatable({}, entity)
critter.__index = critter

critter.activeCritters = {}
critter.inactiveCritters = {}
critter.activeRadius = 128

function critter.new(world, terrain, position)
    local self = setmetatable(entity.new(), Player)

    self.world = world
    self.terrain = terrain
    self.spawn = position
    self.active = false

    self.collider = bf.Collider.new(self.world, "Circle", position.x, position.y, 1)
    self.collider:setFilterData(1, 65535, -1)
    self.collider:setActive(false)
    table.insert(critter.inactiveCritters, self)

    self.dir = 1
    return self
end

function critter.updateActive()
    local radius2 = critter.activeRadius * critter.activeRadius
    local playerPos = player:getPosition()

    for i = #critter.inactiveCritters, 1, -1 do
        local v = critter.inactiveCritters[i]
        if (vector.new(v.collider:getPosition()):dist2(playerPos) <= radius2 ) then
            v:activate()
            table.remove(critter.inactiveCritters, i)
            table.insert(critter.activeCritters, v)
        end
    end

    for i = #critter.activeCritters, 1, -1 do
        local v = critter.activeCritters[i]
        if (vector.new(v.collider:getPosition()):dist2(playerPos) > radius2 ) then
            v:deactivate()
            table.remove(critter.activeCritters, i)
            table.insert(critter.inactiveCritters, v)
        end
    end
end

function critter:murder()
    if (self.deathNoise ~= nil) then
        self.deathNoise:play()
    end
    self:deactivate()
    self.collider:destroy()
    for i, v in ipairs(critter.activeCritters) do
        if (v == self) then table.remove(critter.activeCritters, i); break end
    end
    self.expired = true
end

function critter:activate()
    self.active = true
    self.collider:setActive(true)
    self.terrain:addCollider(self.world, self.collider, 5)
    self:onActivate()
end

function critter:deactivate()
    self.active = false
    self.terrain:removeCollider(self.collider)
    self.collider:setActive(false)
    self:onDeactivate()
end

function critter:onActivate() end

function critter:onDeactivate() end


---------
--------
-------
------
critter.batCritter = setmetatable({}, critter)
critter.batCritter.__index = critter.batCritter
critter.batCritter.flapImpulse = 0.1
critter.batCritter.bouyancy = 0.1

function critter.batCritter.new(world, terrain, position)
    local self = setmetatable(critter.new(world, terrain, position), critter.batCritter)

    self.flapTime = 0

    return self
end

function critter.batCritter:update(dt)
    if (not self.active) then return end

    self.collider:applyForce(0, -self.bouyancy)

    local pos = vector.new(self.collider:getPosition())
    
    local playerPos = player:getPosition()
    local downHit, downPoint = self.terrain:rayCast(pos, vector.new(0, 1), 0.5, 8)
    local upHit, upPoint = self.terrain:rayCast(pos, vector.new(0, -1), 0.5, 8)

    local shouldFlap = false
    if (downHit and not upHit) or (downHit and upHit and downPoint:dist2(pos) < upPoint:dist2(pos)) then
        shouldFlap = true
    end

    local playerDist = pos:dist(playerPos)
    if (playerDist <= 32) then
        local playerDir = playerPos - pos
        --local playerHit, playerPoint = self.terrain:rayCast(pos, playerDir, 0.5, playerDist)

            self:flap(playerDir)
            --TODO: do rads
        --end
    end
end

function critter.batCritter:flap(targetDir)
    local vx, vy = self.collider:getLinearVelocity()
    if (t > self.flapTime and vy < 0) then
        local impulse = (vector.new(-vx, -3):unit()) * self.flapImpulse
        self.collider:applyLinearImpulse(impulse.x, impulse.y)
        
        self.flapTime = t + 0.1
    end
end

function critter.batCritter:draw()
    local pos = vector.new(self.collider:getPosition())
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", pos.x, pos.y, 1)
end


---------
--------
-------
------
critter.slimeCritter = setmetatable({}, critter)
critter.slimeCritter.__index = critter.slimeCritter
critter.slimeCritter.jumpImpulse = 0.2
critter.slimeCritter.radBase = 3
critter.slimeCritter.deathNoise = love.audio.newSource("sounds/slime_pain.wav", "static")
critter.slimeCritter.noise1 = love.audio.newSource("sounds/slime_1.wav", "static")
critter.slimeCritter.noise1:setVolume(0.2)
critter.slimeCritter.noise2 = love.audio.newSource("sounds/slime_2.wav", "static")
critter.slimeCritter.noise2:setVolume(0.2)
critter.slimeCritter.image = love.graphics.newImage("images/slime.png")

function critter.slimeCritter.new(world, terrain, position)
    local self = setmetatable(critter.new(world, terrain, position), critter.slimeCritter)

    self.hopTime = 0
    self.pVel = vector.new(0,0)
    self.collider:setRestitution(0)
    self.vLocked = false

    return self
end

function critter.slimeCritter:update(dt)
    if (not self.active) then return end

    local vel = vector.new(self.collider:getLinearVelocity())
    if (vel:mag2() < self.pVel:mag2() / 10) then --Assume we hit something
        self.vLocked = true
        self.collider:setType("static")
    end
    self.pVel = vel

    local pos = vector.new(self.collider:getPosition())
    
    local playerPos = player:getPosition()
    local playerDist = pos:dist(playerPos)
    local playerDir = playerPos - pos
    local playerHit, playerPoint = self.terrain:rayCast(pos, playerDir, 0.5, playerDist)

    if (not playerHit) then
        self:jump(playerDir:unit() * 2 + vector.new(math.random()-0.5, math.random()-0.5):unit())
        
        local radioactivity = 1/playerDist
        for i = 1, 10 do
            if (math.random() < radioactivity) then
                player:tickRad()
            end
        end
    else 
        self:jump(vector.new(math.random()-0.5, math.random()-0.5):unit())
    end
end

function critter.slimeCritter:jump(targetDir)
    if (t > self.hopTime ) then
        self.vLocked = false
        self.collider:setType("dynamic")

        local impulse = targetDir:unit() * self.jumpImpulse
        self.collider:applyLinearImpulse(impulse.x, impulse.y)
        
        self.hopTime = t + 1 + math.random() * 3

        playNoiseAt(math.random() > 0.5 and self.noise1 or self.noise2, vector.new(self.collider:getPosition()))
    end
end

function playNoiseAt(noise, at)
    local pos = at - player:getPosition()
    local noiseClone = noise:clone()
    noiseClone:setPosition(pos.x, pos.y)
    noiseClone:play()
end

function critter.slimeCritter:draw()
    local pos = vector.new(self.collider:getPosition())
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.image, pos.x, pos.y, 0, 1/100, 1/100, 128, 128)
end

return critter