local physicsEntity = require "physicalentity"

local constructible = {}
constructible.__index = constructible

constructible.ghostShader = love.graphics.newShader(love.filesystem.read("shaders/shadow.frag"), nil)

function constructible.new(sprite, shape, static)
    local self = setmetatable({}, constructible)
    
    self.sprite = sprite
    self.shape = shape
    self.static = static

    return self
end

function constructible:construct(world, position)
    local collider = bf.Collider.new(world, "Polygon", self.shape)
    collider:setPosition(position.x, position.y)
    if (self.static) then
        collider:setType("static")
    else
        levelTerrain:addCollider(world, collider, 15)
    end

    physicsEntity.new(self.sprite, collider)
end

function constructible:canConstruct(world, position)
    return true
end

function constructible:drawGhost(position)
    love.graphics.setColor(1, 0, 0, 0.5)
    love.graphics.setShader(self.ghostShader)
    self.sprite:draw(position.x, position.y)
    love.graphics.setShader()
end

return constructible