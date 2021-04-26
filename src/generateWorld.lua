resourceMap = require "resources"
critter = require "critter"

local worldGenerator = {}

worldGenerator.seed = os.time()
worldGenerator.overflowedFeatures = {}

worldGenerator.terrain1 = love.graphics.newImage("images/terrainTop1.png")
worldGenerator.terrain2 = love.graphics.newImage("images/terrainTop2.png")
worldGenerator.terrain3 = love.graphics.newImage("images/terrainTop3.png")
--worldGenerator.terrain4 = love.graphics.newImage("images/terrainTop4.png")

worldGenerator.caveFeatures = {
    {image = love.graphics.newImage("images/features/cave1.png"), spawnPoints = {vector.new(40, 11), vector.new(45, 11)}},
    {image = love.graphics.newImage("images/features/cave2.png"), spawnPoints = {}},
    {image = love.graphics.newImage("images/features/cave3.png"), spawnPoints = {}},
    {image = love.graphics.newImage("images/features/cave4.png"), spawnPoints = {vector.new(34, 74)}},
}

function worldGenerator.generate(world)
    math.randomseed(worldGenerator.seed)
    local size = vector.new(3, 5)
    local levelTerrain = terrain.new(size.x, size.y)
    levelTerrain:chunkForPoint(vector.new(64, 64)):set(worldGenerator.terrain1)
    levelTerrain:chunkForPoint(vector.new(192, 64)):set(worldGenerator.terrain2)
    levelTerrain:chunkForPoint(vector.new(320, 64)):set(worldGenerator.terrain3)
    --levelTerrain:chunkForPoint(vector.new(448, 64)):set(worldGenerator.terrain4)
    local basePower = wiringEntity.new(vector.new(178, 42), nil)

    local levelResources = resourceMap.new(world, levelTerrain)
    for i = 1, 80 do
        local pos = vector.new(math.random(10, size.x*128-10), math.random(60, size.y*128-10))
        levelResources:addCluster(pos, math.random(5, 10), math.random() > 0.4 and "copper" or "iron")
    end

    for i = 1, 50 do
        local index = math.random(1, #worldGenerator.caveFeatures)
        local feature = worldGenerator.caveFeatures[index]
        local pos = vector.new(math.random(0, size.x*128), math.random(80, size.y*128)) - vector.new(feature.image:getWidth()/2, feature.image:getHeight()/2)
        if (pos.y - feature.image:getHeight() / 2 >= 50) then
            levelTerrain:paint(feature.image, pos.x, pos.y)
            for i, v in ipairs(feature.spawnPoints) do
                if (math.random() > 0.5) then
                    critter.slimeCritter.new(world, levelTerrain, pos + v)
                end
            end
        end
    end

    local leftBound = bf.Collider.new(world, "Rectangle", -4, 0, 4, 128*size.y)
    leftBound:setType("static")
    local rightBound = bf.Collider.new(world, "Rectangle", 128*size.x, 0, 4, 128*size.y)
    rightBound:setType("static")

    return levelTerrain, levelResources
end

function worldGenerator.generateChunk(xOffset, yOffset)
    
end

return worldGenerator