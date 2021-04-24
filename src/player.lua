bf = require "breezefield"
local entity = require "entity"
local collider = require "src.breezefield.collider"

local Player = setmetatable({}, entity)
Player.__index = Player

Player.jumpImpulse = -1.5
Player.moveSpeed = 16
Player.moveForce = 0.5

function Player.new(world, terrain)
    local self = setmetatable(entity.new(), Player)


    self.collider = bf.Collider.new(world, "Circle", 64, 32, 3)
    self.collider:setSleepingAllowed(false)
    terrain:addCollider(world, self.collider, 15)
    table.insert(entity.acceptsInput, self)

    return self
end

function Player:update(dt)
    local playerPosition = vector.new(self.collider:getX(), self.collider:getY())
    local playerVelocity = vector.new(self.collider:getLinearVelocity())

    local intent = vector.new(0, 0)
    if love.keyboard.isDown('a') then intent.x = intent.x - 1 end
    if love.keyboard.isDown('d') then intent.x = intent.x + 1 end
    intent = intent == vector.origin and intent or intent:unit() * self.moveSpeed
    
    local xDelta = intent.x - playerVelocity.x
    self.collider:applyForce(self.moveForce * xDelta, 0)
end

function Player:move(dt)

end

function Player:draw()
    love.graphics.setColor(0.9, 0.8, 0.7, 1)
    love.graphics.circle("fill", self.collider:getX() + 0.5, self.collider:getY() + 0.5, 3)
end

function Player:mousepressed( x, y, button, istouch, presses )

end

function Player:keypressed( key, scancode, isrepeat )
    if (key == 'space') then
        local playerPosition = vector.new(self.collider:getX(), self.collider:getY())
        local feetPosition = playerPosition + vector.new(0, 4)

        local onGround = levelTerrain:valueAt(feetPosition) > 0.5

        if onGround then
            self.collider:applyLinearImpulse(0, self.jumpImpulse)
            print("yump")
        end
    end
end

return Player