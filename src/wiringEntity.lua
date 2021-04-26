local entity = require "entity"

local wiringEntity = setmetatable({}, entity)
wiringEntity.__index = wiringEntity

wiringEntity.nodeImage = love.graphics.newImage("images/wiringNode.png")
wiringEntity.all = {}
wiringEntity.headNode = nil
wiringEntity.lightingImage = love.graphics.newImage("images/lightingCircle.png")

function wiringEntity.new(position, parent)
    local self = setmetatable(entity.new(), wiringEntity)

    self.position = position
    self.parent = parent
    self.children = {}
    if (self.parent == nil) then
        wiringEntity.headNode = self
    else
        table.insert(self.parent.children, self)
    end

    table.insert(wiringEntity.all, self)

    return self
end

function wiringEntity.nearestWiringEntity(position, maxDist, guaranteeVisibility)
    local closestSqr = maxDist * maxDist
    local closestEntity = nil
    for i, v in ipairs(wiringEntity.all) do
        local dist2 = position:dist2(v.position)
        if (dist2 <= closestSqr) then
            local visibleEnough = true
            if (guaranteeVisibility) then
                local dir = position - v.position
                local hit, hitPos = levelTerrain:rayCast(v.position, dir, 0.5, math.huge)
                visibleEnough = (not hit) or (hitPos:dist(v.position) > hitPos:dist(position))
            end
            if (visibleEnough) then
                closestSqr = dist2
                closestEntity = v
            end
        end
    end

    if (closestEntity ~= nil and closestSqr <= maxDist * maxDist) then
        return closestEntity
    end

    return nil
end

function wiringEntity.renderLighting()
    love.graphics.setColor(1, 1, 1, 1)
    for i, v in ipairs(wiringEntity.all) do
        local scale = 0.5 + 0.5 * love.math.noise(t + i * 55.5) ^ 0.25
        if (v.position.y < radDepth) then scale = scale * 0.25 end
        love.graphics.draw(v.lightingImage, v.position.x, v.position.y, 0, scale, scale, 20, 20)
    end
end

function wiringEntity:update(dt)

end

function wiringEntity:draw()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(wiringEntity.nodeImage, self.position.x, self.position.y, 0, 1/32, 1/32, 64, 64)
    love.graphics.setColor(0.1, 0.1, 0.1, 1)
    love.graphics.setLineWidth(0.25)
    for i, v in ipairs (self.children) do
        self.drawDroopyLine(self.position, v.position, 1)
    end
end

local _lineData = {}
function wiringEntity.drawDroopyLine(p1, p2, droopiness)
    for i = 0, 20 do
        local position = lerp1(p1, p2, i/20) - vector.new(0, (((i-10)/10)^2 - 1) * droopiness)
        _lineData[i*2+1] = position.x
        _lineData[i*2+2] = position.y
    end

    love.graphics.line(unpack(_lineData))
end

return wiringEntity