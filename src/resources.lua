local physicalEntity = require "src.physicalEntity"
physicalEntity = physicalEntity or require "physicalEntity"
local sprite = require "src.sprite"
local pickup = require "pickup"
local resourceMap = {}
resourceMap.__index = resourceMap

resourceMap.density = 1/10
resourceMap.sparklePeriod = 10
resourceMap.sprites =  {
    copper = sprite.new(love.graphics.newImage("images/copperChunk.png"), 0, 1/75, 1/75, 100, 100),
    iron = sprite.new(love.graphics.newImage("images/ironChunk.png"), 0, 1/75, 1/75, 100, 100),
}

function resourceMap.new(world, terrain)
    local self = setmetatable({}, resourceMap)

    self.entrainedResources = {}

    self.world = world
    self.terrain = terrain

    return self
end

function resourceMap:addCluster(position, size, resourceType)
    for i = 1, size * size * self.density do
        local randomPos = math.randomInUnitCircle()
        randomPos.x  = randomPos.x * size
        randomPos.y = randomPos.y * size/3
        self:addResource(position + randomPos, resourceType)
    end
end

function resourceMap:addResource(position, resourceType)
    local newRes = {}

    newRes.sparkleOffset = math.random() * 100
    newRes.resourceType = resourceType
    newRes.position = position
    newRes.dead = false

    table.insert(self.entrainedResources, newRes)
end

function resourceMap:dig(position, radius)
    local radius2 = radius * radius
    for i, v in ipairs(self.entrainedResources) do
        if not v.dead and v.position:dist2(position) <= radius2 then
            if self.terrain:valueAt(v.position) < 0.5 then
                self:spawnResourceEntity(self.world, v.position, v.resourceType)
                v.dead = true
            end
        end
    end
end

function resourceMap:spawnResourceEntity(world, position, resourceType)
    local collider = pickup.new(position, resourceType, nil)
    physicalEntity.new(resourceMap.sprites[resourceType], collider)
    collider.parentEntity = physicalEntity
end

resourceMap.sparkleColor = {
    copper = {0.9, 0.5, 0.1},
    iron = {1, 1, 1}
}
function resourceMap:draw()
    for i, v in ipairs(self.entrainedResources) do
        if (not v.dead) and ((t + v.sparkleOffset) % self.sparklePeriod < 0.5) then
            love.graphics.setColor(resourceMap.sparkleColor[v.resourceType])    --TODO: Different colors by resource type
            local sparkleVal = (t + v.sparkleOffset) % self.sparklePeriod
            love.graphics.circle("fill", v.position.x, v.position.y, sparkleVal * 3)
        end
    end
end

return resourceMap