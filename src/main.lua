vudu = require "libs.vudu.vudu.vudu"
bf = require "breezefield"

require "vector"
terrain = require "terrain"
entity = require "entity"
Player = require "player"

function love.load()
    --Infrastructure--
    vudu.initialize()
    love.window.setMode(800, 600)

    --Resources--
    levelTerrainShape = love.graphics.newImage("images/testTerrain.png")
    testTool = love.graphics.newImage("images/testTool.png")

    --Physics--
    world = bf.newWorld(0, 120, true)
    --vudu.physics.setWorld(world)
    --vudu.physics.setTransformation(0, 0, 4, 0)
    vudu.graphics.setTransformation(0, 0, 4, 0)

    --Terrain--
    levelTerrain = terrain.new(2, 2)
    levelTerrain.chunks[1]:set(levelTerrainShape)
    levelTerrain.chunks[2]:set(levelTerrainShape)
    levelTerrain.chunks[3]:set(levelTerrainShape)
    levelTerrain.chunks[4]:set(levelTerrainShape)

    --Entities--
    player = Player.new(world, levelTerrain)

    --Other Globals--
    t = 0

end

function love.update(dt)
    t = t + dt
    levelTerrain:update()
    world:update(dt)
    entity.updateAll(dt)
end

function love.draw()
    love.graphics.scale(4, 4)
    love.graphics.setColor(1, 1, 1, 1)
    levelTerrain:draw()

    entity.drawAll()
    
    --[[
    local mx, my = love.mouse.getPosition()
    mx = mx / 4
    my = my / 4
    local ray = vector.fromPolar(1, t)
    local hit, hitSpot = levelTerrain:rayCast(vector.new(mx, my), ray, 0.5, 10)

    --print(vector.new(mx, my))
    --print(hitSpot)

    if (hit) then
        love.graphics.setColor(1, 0, 0, 1)
        love.graphics.setLineWidth(0.25)
        love.graphics.line(mx, my, hitSpot.x, hitSpot.y)
        love.graphics.setColor(0, 1, 0, 0.5)
        love.graphics.line(mx, my, mx + ray.x * 5, my + ray.y * 5)
    end
    ]]
end

function love.mousepressed( x, y, button, istouch, presses ) 
    --love.graphics.translate(-testTool:getWidth()/2, -testTool:getHeight()/2)
    levelTerrain:paint(testTool, x / 4, y / 4, testTool:getWidth()/2, testTool:getHeight()/2)

    entity.mousepressedAll(x, y, button, istouch, presses)
end

function love.keypressed( key, scancode, isrepeat )
    entity.keypressedAll(key, scancode, isrepeat)
end