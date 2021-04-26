require ("extraMath")

local terrainChunk = {}
terrainChunk.__index = terrainChunk

local terrainCollider = {}
terrainCollider.__index = terrainCollider

local terrain = {}
terrain.__index = terrain

terrain.baseShader = love.graphics.newShader(love.filesystem.read("shaders/terrain.frag"), nil)
terrain.baseShader:send("cutoff", 0.5)
terrain.baseShader:send("noise", love.graphics.newImage("images/rockNoise.png"))
local gradient = love.graphics.newImage("images/StoneGradient.png")
gradient:setFilter("nearest", "nearest")
terrain.baseShader:send("gradient", gradient)

terrain.chunkSize = 128

function terrain.new(initX, initY)
    local self = setmetatable({}, terrain)
    self.terrainColliders = {}
    self.chunks = {}

    for i = 0, initX-1 do for j = 0, initY-1 do
        table.insert(self.chunks, terrainChunk.new(i, j))
    end end

    return self
end

function terrain:update()
    for i, v in ipairs(self.terrainColliders) do
        v:update(false)
    end
end

function terrain:draw()
    for i, tc in ipairs(self.chunks) do
        tc:draw()
    end
end

function terrain:paint(toolImage, x, y, ox, oy, strength)
    for i, tc in ipairs(self.chunks) do
        tc:paint(toolImage, x, y, ox, oy, strength)
    end

    for i, v in ipairs(self.terrainColliders) do
        v:update(true)
    end
end

--This is inefficient, but might be enough
function terrain:chunkForPoint(point)
    for i, tc in ipairs(self.chunks) do
        if (tc:pointInBounds(point)) then return tc end
    end

    return nil
end

function terrain:rayCast(point, ray, hitVal, maxDist, stepsSoFar)
    stepsSoFar = stepsSoFar or 1

    if self:valueAt(point) > hitVal then 
        return true, point 
    elseif ray == vector.origin then
        return false, point
    end

    local stepper = point:copy()
    local hit = false
    local chunk = self:chunkForPoint(stepper)

    while chunk ~= nil and stepsSoFar < 2000 do
        hit, stepper, stepsSoFar = chunk:rayCast(stepper, ray, hitVal, maxDist, stepsSoFar)
        if hit then 
            local tooFar = point:dist(stepper) > maxDist
            return not tooFar, stepper 
        end
        local nextChunk = self:chunkForPoint(stepper)
        chunk = chunk == nextChunk and nil or nextChunk
    end
    
    return false, stepper
end

function terrain:valueAt(point) 
    local chunk = self:chunkForPoint(point)
    if (chunk ~= nil) then return chunk:getExactValue(point) end
    return 1
end

function terrain:gradientAt(point)
    local l = self:valueAt(point + vector.new(-0.25, 0))
    local r = self:valueAt(point + vector.new(0.25, 0))
    local u = self:valueAt(point + vector.new(0, -0.25))
    local d = self:valueAt(point + vector.new(0, 0.25))

    return vector.new(r-l, d-u):unit()
end

function terrain:addCollider(world, collider, radius)
    local tc = terrainCollider.new(self, world, collider, radius)
    collider.terrainCollider = tc
    table.insert(self.terrainColliders, tc)
end

function terrain:removeCollider(collider)
    local tc = collider.terrainCollider

    tc:cleanup()
    local index = -1
    for i, v in ipairs(self.terrainColliders) do
        if (v == tc) then index = i; break; end
    end

    if index ~= -1 then
        table.remove(self.terrainColliders, index)
    end
end


-------------------
------------------
-----------------
----------------
function terrainChunk.new(offsetX, offsetY)
    local self = setmetatable({}, terrainChunk)

    self.offsetX = offsetX
    self.offsetY = offsetY

    --Save these values because they won't change, I'll use them a bunch, and I don't want to recalculate them a bunch
    self.leftBound = self.offsetX * terrain.chunkSize
    self.topBound = self.offsetY * terrain.chunkSize
    self.rightBound = self.leftBound + terrain.chunkSize
    self.bottomBound = self.topBound + terrain.chunkSize
    
    self.terrainCanvas = love.graphics.newCanvas(terrain.chunkSize, terrain.chunkSize)
    love.graphics.setCanvas(self.terrainCanvas)
    love.graphics.clear(1, 1, 1, 1)
    love.graphics.setCanvas()

    self.offboardTerrain = self.terrainCanvas:newImageData()
    self.offboardDirty = false  --If offboardDirty is true, then offboardTerrain is out of date with the canvas

    return self
end

function terrainChunk:draw()
    terrain.baseShader:send("topDepth", self.offsetY / 5)
    terrain.baseShader:send("bottomDepth", self.offsetY / 5 + 0.2)
    love.graphics.setShader(terrain.baseShader)
    love.graphics.draw(self.terrainCanvas, self.leftBound, self.topBound)
    love.graphics.setShader()
end

function terrainChunk:pointInBounds(point)
    local inBounds = point.x >= self.leftBound and point.x < self.rightBound and point.y >= self.topBound and point.y < self.bottomBound
    return inBounds
end

--Raycast in the given direction until the desired value is encountered
--returns: (whether the ray hit), (where iteration finished)
function terrainChunk:rayCast(point, ray, hitVal, maxDist, stepsSoFar)
    if not self:pointInBounds(point) then return false, point, stepsSoFar end
    if self.offboardDirty then self:refreshOffboard() end

    local stepper = point
    local stride = 1
    local strideRay = ray:unit() * stride;

    repeat
        local val = self:getExactValue(stepper)
        if (val >= hitVal) then 
            while (stride > 0.001) do   --desired accuracy of 0.001
                stride = stride / 2
                if (val > hitVal) then stepper = stepper - strideRay * stride else stepper = stepper + strideRay * stride end
                if (self:pointInBounds(stepper)) then
                    val = self:getExactValue(stepper)
                else
                    return true, stepper, stepsSoFar
                end
            end

            return true, stepper, stepsSoFar
        end
        stepper = stepper + strideRay
        stepsSoFar = stepsSoFar + 1
    until stepsSoFar > 2000 or not self:pointInBounds(stepper)

    return false, stepper, stepsSoFar
end

function terrainChunk:getExactValue(point)
    if self.offboardDirty then self:refreshOffboard() end
    point = point - vector.new(self.leftBound + 0.5, self.topBound + 0.5)

    local px = point.x % 1
    local py = point.y % 1

    local x0 = math.max(0, point.x)
    local y0 = math.max(0, point.y)
    local x1 = math.min(point.x + 1, terrain.chunkSize-1)
    local y1 = math.min(point.y + 1, terrain.chunkSize-1)

    local v00 = self.offboardTerrain:getPixel(x0, y0)
    local v10 = self.offboardTerrain:getPixel(x1, y0)
    local v01 = self.offboardTerrain:getPixel(x0, y1)
    local v11 = self.offboardTerrain:getPixel(x1, y1)

    return math.bilinearInterpolate(vector.new(px, py), v00, v10, v01, v11)
end

function terrainChunk:paint(toolImage, x, y, ox, oy, strength) 
    love.graphics.setBlendMode("subtract", "premultiplied")
    love.graphics.setCanvas(self.terrainCanvas)

    love.graphics.setColor(1, 0, 0, strength)
    love.graphics.draw(toolImage, x - self.leftBound, y - self.topBound, 0, 1, 1, ox, oy)

    love.graphics.setCanvas()
    love.graphics.setBlendMode("alpha")
    self.offboardDirty = true
end

function terrainChunk:set(image)
    love.graphics.setCanvas(self.terrainCanvas)
    love.graphics.draw(image, 0, 0)
    love.graphics.setCanvas()
    self.offboardDirty = true
end

function terrainChunk:refreshOffboard()
    self.offboardTerrain:release()
    self.offboardTerrain = self.terrainCanvas:newImageData()
    self.offboardDirty = false
end


-------------------
------------------
-----------------
----------------
terrainCollider.bristleRadius = 0.5
function terrainCollider.new(terrain, world, collider, radius, important)
    local self = setmetatable({}, terrainCollider)

    self.world = world
    self.terrain = terrain
    self.collider = collider
    self.radius = radius

    self.bristles = {}
    self.bristleCount = important and 32 or 12
    for i = 1, self.bristleCount do
        local dir = math.pi * 2 * (i/self.bristleCount)
        local pos = vector.new(collider:getX(), collider:getY()) + vector.fromPolar(radius, dir)
        local collider = bf.Collider.new(world, "Circle", pos.x, pos.y, terrainCollider.bristleRadius)
        collider:setType("static")

        self.bristles[i] = {
            dir = dir,
            pos = pos,
            collider = collider
        }
    end

    return self
end

function terrainCollider:cleanup()
    for i, v in ipairs(self.bristles) do
        v.collider:destroy()
    end
end

function terrainCollider:update(forceUnpin)
    forceUnpin = true   --TODO: seems like this is just the best option here
    local colliderPos = vector.new(self.collider:getX(), self.collider:getY())
    for i, v in ipairs(self.bristles) do
        local pinned = not forceUnpin and (colliderPos:dist2(v.pos) < 16 and #v.collider:getContacts() > 0)

        local bristlePos = vector.new(v.collider:getX(), v.collider:getY())
        if not pinned then
            local dir = vector.fromPolar(1, v.dir)
            local hit, hitPos = self.terrain:rayCast(colliderPos, dir, 0.5, self.radius)
            local degenerate = not hit or hitPos:dist2(colliderPos) < 0.04
            if not degenerate then
                if (v.degenerate) then v.collider:setActive(true) end
                v.degenerate = false

                v.pos = hitPos
                local grad = hit and self.terrain:gradientAt(hitPos) or dir
                local bristlePos = hitPos + grad * terrainCollider.bristleRadius
                v.collider:setPosition(bristlePos.x, bristlePos.y)
            else
                if not v.degenerate then v.collider:setActive(false) end
                v.degenerate = true
            end
        end

        --vudu.graphics.drawCircle({0, 1, 1}, 0, bristlePos.x, bristlePos.y, terrainCollider.bristleRadius, 0.25)
    end
end

return terrain