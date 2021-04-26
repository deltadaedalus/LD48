--vudu = require "libs.vudu.vudu.vudu"
bf = require "breezefield"
wiringEntity = require "wiringentity"

require "vector"
terrain = require "terrain"
entity = require "entity"
Player = require "player"
ui = require "ui"
physicalEntity = require("physicalentity")
worldGenerator = require "generateWorld"

winSize = vector.new(800, 600)

function love.load()
    --Infrastructure--
    --vudu.initialize()
    --vudu.setTheme("libs/vudu/vudu/vudu/themes/glassy.lua")
    love.window.setFullscreen(true, "desktop")
    --love.window.setMode(800, 600)

    --Resources--
    levelTerrainShape = love.graphics.newImage("images/testTerrain.png")
    testTool = love.graphics.newImage("images/testTool.png")

    --Physics--
    world = bf.newWorld(0, 100, true)
    --vudu.physics.setWorld(world)

    --Terrain--
    levelTerrain, levelResources = worldGenerator.generate(world)
    --levelTerrain = terrain.new(2, 2)
    --levelTerrain.chunks[1]:set(levelTerrainShape)
    --levelTerrain.chunks[2]:set(levelTerrainShape)
    --levelTerrain.chunks[3]:set(levelTerrainShape)
    --levelTerrain.chunks[4]:set(levelTerrainShape)

    --Entities--
    player = Player.new(world, levelTerrain)
    --critter.slimeCritter.new(world, levelTerrain, vector.new(173, 45))

    --Other Globals--
    camera = {
        laxadaisicality = 0.1,
        position = player:getPosition(),
        target = player:getPosition(),
        zoom = 4,
        targetZoom = 15 * winSize.y/600,
        transform = love.math.newTransform()
    }

    font = love.graphics.newFont("fonts/fyodor.bold.ttf", 48, "normal", 48)

    lightingCanvas = love.graphics.newCanvas(winSize.x, winSize.y)
    lightingShader = love.graphics.newShader(love.filesystem.read("shaders/lightOverlay.frag"), nil)
    lightingShader:send("innerCutoff", 0.7)
    lightingShader:send("outerCutoff", 0.9)
    lightingShader:sendColor("shadowColor", {0, 0, 0.025, 0.9})

    introOverlay = love.graphics.newImage("images/intro.png")

    worldBottom = 5*128

    radDepth = 0

    bgImg = love.graphics.newImage("images/sky.png")

    t = 0

    tutorial.advance()

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

    tutorial.update()

    if (tutorial.complete and player:getPosition().y > radDepth + 16) then radDepth = radDepth + dt * 0.5 end

    if (not gameCompleted and player:getPosition().y > worldBottom - 16) then
        gameCompleted = true
        completedTime = t
    end

    if (gameCompleted and t - completedTime > 15) then love.event.quit() end
end

function updateCamera(dt)
    camera.target = player:getPosition()
    camera.position = lerp1(camera.target, camera.position, camera.laxadaisicality^dt)
    camera.zoom = lerp1(camera.targetZoom, camera.zoom, camera.laxadaisicality^dt)

    --enforce boundaries
    local leftBound, rightBound, topBound, bottomBound = 0, 128*3, 0, 128*5
    camera.position.x = math.max(camera.position.x, leftBound + winSize.x / camera.zoom / 2)
    camera.position.x = math.min(camera.position.x, rightBound - winSize.x / camera.zoom / 2)
    camera.position.y = math.max(camera.position.y, topBound + winSize.y / camera.zoom / 2)
    camera.position.y = math.min(camera.position.y, bottomBound + winSize.y / camera.zoom / 2)

    camera.transform = love.math.newTransform(-camera.position.x * camera.zoom, -camera.position.y * camera.zoom, 0, camera.zoom, camera.zoom, -winSize.x/2/camera.zoom, -winSize.y/2/camera.zoom)
    
    --vudu.physics.setTransformation(-camera.position.x / camera.zoom, -camera.position.y / camera.zoom, camera.zoom, 0)
    --vudu.graphics.setTransformation(-camera.position.x/2, -camera.position.y/2, camera.zoom, 0)
end

function love.draw()
    love.graphics.setFont(font)
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(bgImg, 0, 0, 0, winSize.x / 800, winSize.y / 600)

    love.graphics.push()
    love.graphics.applyTransform(camera.transform)
    love.graphics.setColor(1, 1, 1, 1)
    levelTerrain:draw()
    levelResources:draw()

    entity.drawAll()

    renderLighting()
    love.graphics.pop()

    if (t < 10) then
        lightingShader:send("innerCutoff", 0.5 * t/10)
        lightingShader:send("outerCutoff", 0.9 * t/10)
    else
        lightingShader:send("innerCutoff", 0.5)
        lightingShader:send("outerCutoff", 0.9)
    end
    love.graphics.setShader(lightingShader)
    love.graphics.draw(lightingCanvas)
    love.graphics.setShader()

    ui.draw()

    if (t < 10) then
        love.graphics.setColor(1, 1, 1, math.min(1, 1.5 - t * 1.5/10))
        love.graphics.draw(introOverlay, winSize.x/2, winSize.y/2, 0, winSize.y/750, winSize.y/750, 1000, 375)
    end

    if (gameCompleted) then
        love.graphics.setColor(1, 1, 1, math.min(1, (t - completedTime) / 10))
        love.graphics.draw(introOverlay, winSize.x/2, winSize.y/2, 0, winSize.y/750, winSize.y/750, 1000, 375)
    end
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
    if (key == 't') then tutorial.skip() end
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
    local volumeForHeight = lerp1(0.01, 0.15, player:getPosition().y / worldBottom)
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








textBubbleEntity = setmetatable({}, entity)
textBubbleEntity.__index = textBubbleEntity

function textBubbleEntity.new(text, position, expirationCondition) 
    local self = setmetatable(entity.new(), textBubbleEntity)
    
    self.expirationTime = math.huge
    self.expirationCondition = expirationCondition
    self.conditionDetected = false
    self.text = text
    self.position = position

    table.remove(entity.all, #entity.all)
    table.insert(entity.all, 1, self)   --Scoot the text to the top

    return self
end

function textBubbleEntity:update(dt)
    if t > self.expirationTime then
        self.expired = true
    end

    if (self.expirationCondition ~= nil and self.conditionDetected == false) then
        if (self.expirationCondition()) then
            self.expirationTime = t+1
        end
    end
end

function textBubbleEntity:scheduleExpiration(delay)
    self.expirationTime = t + delay
end

function textBubbleEntity:draw()
    local opacity = 1
    if (t > self.expirationTime - 1) then
        opacity = (self.expirationTime - t) / 1
    end
    love.graphics.setColor(0.6, 0.9, 0.1, opacity * 0.8)
    --love.graphics.printf(self.text, self.position.x, self.position.y, 0, "center", 0, 1, 1)
    love.graphics.print(self.text, self.position.x, self.position.y, 0, 1/36, 1/36)
end

function textBubbleEntity:isDone()
    return t > self.expirationTime
end

tutorial = {
    commplete = false,
    states = {
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("The Radiation\nhas been increasing...", player:getPosition() + vector.new(2, 0), nil)
                tutorial.currentText:scheduleExpiration(15)
            end,
            doneCondition = function() return tutorial.currentText:isDone() end,
            teardown = function() end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("My suit will keep me safe\nas long as I have power...", player:getPosition() + vector.new(2, 0), nil)
                tutorial.currentText:scheduleExpiration(5)
            end,
            doneCondition = function() return tutorial.currentText:isDone() end,
            teardown = function() end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("But the way things are going\nthe suit won't keep up...", player:getPosition() + vector.new(2, 0), nil)
                tutorial.currentText:scheduleExpiration(5)
            end,
            doneCondition = function() return tutorial.currentText:isDone() end,
            teardown = function() end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("I need to go deeper.", player:getPosition() + vector.new(2, 0), nil)
                tutorial.currentText:scheduleExpiration(5)
            end,
            doneCondition = function() return tutorial.currentText:isDone() end,
            teardown = function() end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("I can move with WASD\nI can jump with SPACE", player:getPosition() + vector.new(2, 0), nil)
            end,
            doneCondition = function() return love.keyboard.isDown('w') or love.keyboard.isDown('a') or love.keyboard.isDown('s') or love.keyboard.isDown('d') or love.keyboard.isDown('space') end,
            teardown = function() tutorial.currentText.expired = true end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("I can choose tools with Q/E\nor the NUMBER KEYS", player:getPosition() + vector.new(2, 0), nil)
            end,
            doneCondition = function() return player.toolIndex ~= 1 end,
            teardown = function() tutorial.currentText.expired = true end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("My first tool is this rusty pick\nwith MOUSE I can dig", player:getPosition() + vector.new(2, 0), nil)
            end,
            doneCondition = function() return player.toolIndex == 1 and love.mouse.isDown(1) end,
            teardown = function() tutorial.currentText.expired = true  end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("My second is a mining laser\nIt takes a lot of power\nIt makes a good weapon", player:getPosition() + vector.new(2, 0), nil)
                tutorial.currentText:scheduleExpiration(7)
            end,
            doneCondition = function() return tutorial.currentText:isDone() end,
            teardown = function() end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("My third is wires\nIf I have Copper\nI can extend my power network", player:getPosition() + vector.new(2, 0), nil)
                tutorial.currentText:scheduleExpiration(7)
            end,
            doneCondition = function() return tutorial.currentText:isDone() end,
            teardown = function() end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("I have copper now\nIf I press 3, click my power station\nAnd click somewhere else\nIt will create a new station", player:getPosition() + vector.new(2, 0), nil)
            end,
            doneCondition = function() return #wiringEntity.all > 1 end,
            teardown = function() tutorial.currentText.expired = true end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("My fourth is scaffolding\nI need iron to make them\nBut they help me get around", player:getPosition() + vector.new(2, 0), nil)
                tutorial.currentText:scheduleExpiration(7)
            end,
            doneCondition = function() return tutorial.currentText:isDone() end,
            teardown = function() end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("To find metal\nI should look for sparkles in the walls\nI can only hold a few", player:getPosition() + vector.new(2, 0), nil)
                tutorial.currentText:scheduleExpiration(5)
            end,
            doneCondition = function() return tutorial.currentText:isDone() end,
            teardown = function() end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("I must mind my battery\nIt will alarm before it runs out\nBut that might be too late", player:getPosition() + vector.new(2, 0), nil)
                tutorial.currentText:scheduleExpiration(5)
            end,
            doneCondition = function() return tutorial.currentText:isDone() end,
            teardown = function() end
        },
        {
            spinup = function() 
                tutorial.currentText = textBubbleEntity.new("I hope somewhere deeper\nThe rock will protect me\nI can only dig", player:getPosition() + vector.new(2, 0), nil)
                tutorial.currentText:scheduleExpiration(5)
            end,
            doneCondition = function() return tutorial.currentText:isDone() end,
            teardown = function() end
        },
    }
}

tutorial.currentState = nil
tutorial.stateIndex = 0

function tutorial.update(dt)
    if (not tutorial.complete) then
        if (tutorial.currentState.doneCondition and tutorial.currentState.doneCondition()) then
            tutorial.advance()
        end
    end
end

function tutorial.advance()
    if (tutorial.currentState) then
        tutorial.currentState.teardown()
    end

    tutorial.stateIndex = tutorial.stateIndex + 1
    tutorial.currentState = tutorial.states[tutorial.stateIndex]
    if (tutorial.currentState) then
        if (tutorial.currentState.spinup) then
            tutorial.currentState.spinup()
        end
    else
        tutorial.complete = true
    end
end

function tutorial.skip()
    if (tutorial.currentState) then
        tutorial.currentState.teardown()
    end
    tutorial.complete = true
end