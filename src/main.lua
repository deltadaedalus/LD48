vudu = require "libs.vudu.vudu.vudu"
bf = require "breezefield"
wiringEntity = require "wiringEntity"
local physicalEntity = require "src.physicalEntity"

require "vector"
terrain = require "terrain"
entity = require "entity"
Player = require "player"
ui = require "ui"
physicalEntity = require("physicalEntity")
worldGenerator = require "generateWorld"

winSize = vector.new(800, 600)

function love.load()
    --Infrastructure--
    vudu.initialize()
    vudu.setTheme("libs/vudu/vudu/vudu/themes/glassy.lua")
    love.window.setFullscreen(true, "desktop")
    --love.window.setMode(800, 600)

    --Resources--
    levelTerrainShape = love.graphics.newImage("images/testTerrain.png")
    testTool = love.graphics.newImage("images/testTool.png")

    --Physics--
    world = bf.newWorld(0, 120, true)
    vudu.physics.setWorld(world)

    --Terrain--
    levelTerrain, levelResources = worldGenerator.generate(world)
    --levelTerrain = terrain.new(2, 2)
    --levelTerrain.chunks[1]:set(levelTerrainShape)
    --levelTerrain.chunks[2]:set(levelTerrainShape)
    --levelTerrain.chunks[3]:set(levelTerrainShape)
    --levelTerrain.chunks[4]:set(levelTerrainShape)

    --Entities--
    player = Player.new(world, levelTerrain)
    critter.slimeCritter.new(world, levelTerrain, vector.new(173, 45))

    --Other Globals--
    camera = {
        laxadaisicality = 0.1,
        position = player:getPosition(),
        target = player:getPosition(),
        zoom = 4,
        targetZoom = 15 * winSize.y/600,
        transform = love.math.newTransform()
    }

    lightingCanvas = love.graphics.newCanvas(winSize.x, winSize.y)
    lightingShader = love.graphics.newShader(love.filesystem.read("shaders/lightOverlay.frag"), nil)
    lightingShader:send("innerCutoff", 0.7)
    lightingShader:send("outerCutoff", 0.9)
    lightingShader:sendColor("shadowColor", {0, 0, 0.025, 0.9})

    worldBottom = 1024

    t = 0

end

function love.resize(w, h)
    winSize = vector.new(w, h)

    lightingCanvas = love.graphics.newCanvas(winSize.x, winSize.y)
end

function love.update(dt)
    t = t + dt
    updateCamera(dt)
    levelTerrain:update()
    world:update(dt)
    entity.updateAll(dt)
    ui.update(dt)
    updateAmbient(dt)
    critter.updateActive()
end

function updateCamera(dt)
    camera.target = player:getPosition()
    camera.position = lerp1(camera.target, camera.position, camera.laxadaisicality^dt)
    camera.zoom = lerp1(camera.targetZoom, camera.zoom, camera.laxadaisicality^dt)
    camera.transform = love.math.newTransform(-camera.position.x * camera.zoom, -camera.position.y * camera.zoom, 0, camera.zoom, camera.zoom, -winSize.x/2/camera.zoom, -winSize.y/2/camera.zoom)
    
    vudu.physics.setTransformation(-camera.position.x / camera.zoom, -camera.position.y / camera.zoom, camera.zoom, 0)
    vudu.graphics.setTransformation(-camera.position.x/2, -camera.position.y/2, camera.zoom, 0)
end

function love.draw()
    love.graphics.push()
    love.graphics.applyTransform(camera.transform)
    love.graphics.setColor(1, 1, 1, 1)
    levelTerrain:draw()
    levelResources:draw()

    entity.drawAll()

    renderLighting()
    love.graphics.pop()
    love.graphics.setShader(lightingShader)
    love.graphics.draw(lightingCanvas)
    love.graphics.setShader()

    ui.draw()
end

function love.mousepressed( x, y, button, istouch, presses ) 
    --love.graphics.translate(-testTool:getWidth()/2, -testTool:getHeight()/2)
    --levelTerrain:paint(testTool, x / 4, y / 4, testTool:getWidth()/2, testTool:getHeight()/2)

    if (not ui.mousepressed(x, y, button, false)) then
        entity.mousepressedAll(x, y, button, istouch, presses)
    else
        player.currentTool.toolRefresh = t + 0.25
    end
end

function love.keypressed( key, scancode, isrepeat )
    entity.keypressedAll(key, scancode, isrepeat)
end

function screenToWorld( screenPos )
    return vector.new(camera.transform:inverseTransformPoint(screenPos.x, screenPos.y))
end

function renderLighting()
    love.graphics.setCanvas(lightingCanvas)
    love.graphics.setBlendMode("subtract", "premultiplied")

    love.graphics.clear(1, 1, 1, 1)

    player:renderLighting()
    wiringEntity.renderLighting()

    love.graphics.setBlendMode("alpha")
    love.graphics.setCanvas()
end

local ambientNoises = {
    love.audio.newSource("sounds/clatter.wav", "stream"),
    love.audio.newSource("sounds/dragon_breath.wav", "stream"),
    love.audio.newSource("sounds/eerie_rushing.wav", "stream"),
    love.audio.newSource("sounds/gravel_falling.wav", "stream"),
    love.audio.newSource("sounds/mountain_groan.wav", "stream")
}

function updateAmbient(dt)
    local volumeForHeight = lerp1(0.01, 0.25, player:getPosition().y / worldBottom)
    --We always want at least two of these playing
    local playingCount = 0
    for i, v in ipairs(ambientNoises) do
        if (v:isPlaying()) then playingCount = playingCount + 1 end
    end

    if (playingCount < 2 or playingCount < 3 and math.random() < dt/10) then
        local index = math.random(1, #ambientNoises)
        while (ambientNoises[index]:isPlaying()) do
            index = index % #ambientNoises + 1
        end

        ambientNoises[index]:setVolume(volumeForHeight)
        ambientNoises[index]:play()
    end
end