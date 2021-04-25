local entity = require "entity"

local physicsEntity = setmetatable({}, entity)
physicsEntity.__index = physicsEntity

function physicsEntity.new(sprite, collider)
    local self = setmetatable(entity.new(), physicsEntity)

    self.sprite = sprite
    self.collider = collider

    return self
end

function physicsEntity:update(dt)

end

function physicsEntity:draw()
    if (not self.collider:isDestroyed()) then   --TODO: There's a memory leak here
        local entPos = vector.new(self.collider:getX(), self.collider:getY())
        local entRot = self.collider:getAngle()
        love.graphics.setColor(1, 1, 1, 1)
        self.sprite:draw(entPos.x, entPos.y, entRot)
    end
end

return physicsEntity