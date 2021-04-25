local ui = {}

ui.vignette = love.graphics.newImage("images/vignette.png")

function ui.update(dt)
    ui.updateGeigerCounter(dt)
    ui.updateBattery(dt)
    ui.updateInventory(dt)
    ui.updateTools(dt)
end

function ui.draw()
    ui.drawGeigerCounter()
    ui.drawBattery()
    ui.drawInventory()
    ui.drawTools()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ui.vignette, 0, 0, 0, winSize.x/800, winSize.y/600)
end

function ui.mousepressed(x, y, button, isRepeat)
    if ui.mousepressedInventory(x, y, button, isRepeat) then
        return true
    else
        return ui.mousepressedTools(x, y, button, isRepeat)
    end
end


-------
------
-----
----
ui.geigerTicksToPlay = 0
function ui.tickGeigerCounter()
    ui.geigerTicksToPlay = ui.geigerTicksToPlay + 1
end

ui.geigerValue = 0
ui.geigerMax = 100
ui.geigerDecay = 0.8
ui.tickSource = love.audio.newSource("sounds/geigerTick.wav", "static")
function ui.updateGeigerCounter(dt)
    ui.geigerValue = ui.geigerValue * ui.geigerDecay ^ dt
    for i = 1, ui.geigerTicksToPlay do
        local clone = ui.tickSource:clone()
        clone:seek(math.random() * 0.02)    --Offset by a random amount so that a bunch playing on the same tick sounds right
        clone:play()    --TODO: Memory Leak?
        ui.geigerValue = math.min(ui.geigerValue + 1, ui.geigerMax)
    end
    ui.geigerTicksToPlay = 0
end

ui.geigerBack = love.graphics.newImage("images/geigerBack.png")
ui.geigerDial = love.graphics.newImage("images/geigerDial.png")
ui.geigerFront = love.graphics.newImage("images/geigerTop.png")
ui.geigerPos = vector.new(-220, -320)
ui.geigerScale = 0.5
function ui.drawGeigerCounter()
    love.graphics.push()
    local gScale = ui.geigerScale * winSize.y/600
    love.graphics.translate(winSize.x + ui.geigerPos.x * gScale, winSize.y + ui.geigerPos.y * gScale)
    love.graphics.scale(gScale)

    local angle = -math.pi/4 + (math.min(ui.geigerValue, ui.geigerMax) / ui.geigerMax) * math.pi/2
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ui.geigerBack, 0, 0)
    love.graphics.draw(ui.geigerDial, 105, 147, angle, 1, 1, 105, 147)
    love.graphics.draw(ui.geigerFront, 0, 0)

    love.graphics.pop()
end


-------
------
-----
----
ui.lowBatterySound = love.audio.newSource("sounds/low_battery.wav", "static")
ui.lowBatterySound:setLooping(true)
function ui.updateBattery()
    local value = player.energy / player.maxEnergy
    if (value < 0.2) then
        ui.lowBatterySound:play()
    else
        ui.lowBatterySound:stop()
    end
end

ui.batteryPos = vector.new(-500, -125)
ui.batteryBarDist = 10
ui.batteryBarImage = love.graphics.newImage("images/batteryBar.png")
ui.batteryBack = love.graphics.newImage("images/batteryBack.png")
ui.batteryTop = love.graphics.newImage("images/batteryTop.png")
ui.batteryColors = {
    {0.6, 0, 0, 1},
    {0.6, 0, 0, 1},
    {0.6, 0.4, 0, 1},
    {0.6, 0.4, 0, 1},
    {0.6, 0.4, 0, 1},
    {0, 0.6, 0, 1},
    {0, 0.6, 0, 1},
    {0, 0.6, 0, 1},
    {0, 0.6, 0, 1},
    {0, 0.4, 0.6, 1},
}

ui.batteryRects = {
    {48, 17},
    {66, 19},
    {85, 18},
    {103, 18},
    {122, 18},
    {141, 19},
    {161, 21},
    {183, 18},
    {202, 17},
    {220, 17},
}

ui.batteryDarkColor = {0.1, 0.1, 0.1, 0}
function ui.drawBattery()
    love.graphics.push()
    local gScale = ui.geigerScale * winSize.y/600
    love.graphics.translate(winSize.x + ui.batteryPos.x * gScale, winSize.y + ui.batteryPos.y * gScale)
    love.graphics.scale(gScale)

    local pastFlasher = false
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ui.batteryBack)
    for i = 0, 9 do
        local isFlasher = math.floor(10 * player.energy / player.maxEnergy) == i
        local flashOff = t % 1 > (10 * player.energy / player.maxEnergy) % 1 
        love.graphics.setColor((pastFlasher or isFlasher and flashOff) and ui.batteryDarkColor or ui.batteryColors[i+1])
        love.graphics.rectangle("fill", ui.batteryRects[i+1][1], 35, ui.batteryRects[i+1][2], 44)
        if (isFlasher) then pastFlasher = true end
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ui.batteryTop)

    
    love.graphics.pop()
end



-------
------
-----
----
ui.inventoryHoveredIndex = nil
ui.inventoryX = 10
ui.inventoryY = 10
function ui.updateInventory()
    local mousePos = vector.new(love.mouse.getPosition())
    local hoveredIndex = nil
    if (ui.inventoryX <= mousePos.x and mousePos.x <= ui.inventoryX + 100) then    --TODO: scale
        local ny = winSize.y - mousePos.y
        if (ui.inventoryY <= ny and ny <= ui.inventoryY + 50 + #player.heldItems * 50) then
            if (ny < ui.inventoryY + 50) then hoveredIndex = #player.heldItems
            else hoveredIndex = #player.heldItems - (math.floor((ny-ui.inventoryY - 50)/50))
            end
        end
    end

    ui.inventoryHoveredIndex = hoveredIndex
end

function ui.mousepressedInventory(x, y, button, isRepeat)
    if ui.inventoryHoveredIndex ~= nil then
        table.remove(player.heldItems, ui.inventoryHoveredIndex)
        return true
    end
end

ui.inventoryIcons = {
    copper = love.graphics.newImage("images/copperIcon.png"),
    iron = love.graphics.newImage("images/ironIcon.png")
}
function ui.drawInventory()
    for i, v in ipairs(player.heldItems) do
        love.graphics.setColor(i == ui.inventoryHoveredIndex and {.8, .8, .8, 1} or {1, 1, 1, 1})
        love.graphics.draw(ui.inventoryIcons[v], ui.inventoryX, winSize.y - 100 - ui.inventoryY - ((#player.heldItems - i)) * 50)    --TODO: scale
    end
end


-------
------
-----
----
ui.toolHoveredIndex = nil
ui.toolX = 120
ui.toolY = 10
function ui.updateTools()
    local mousePos = vector.new(love.mouse.getPosition())
    local hoveredIndex = nil
    if (ui.toolX <= mousePos.x and mousePos.x <= ui.toolX + 50) then    --TODO: scale
        local ny = winSize.y - mousePos.y
        if (ui.toolY <= ny and ny <= #player.toolList * (ui.toolY + 50)) then
            hoveredIndex = math.ceil(ny / 60)
            if (hoveredIndex > #player.toolList) then hoveredIndex = nil end
        end
    end

    ui.toolHoveredIndex = hoveredIndex
end

function ui.mousepressedTools(x, y, button, isRepeat)
    if ui.toolHoveredIndex ~= nil then
        player.toolIndex = ui.toolHoveredIndex
        player.currentTool = player.toolList[player.toolIndex]
        return true
    end
end

ui.toolsBackground = love.graphics.newImage("images/toolBG.png")
function ui.drawTools()
    for i, v in ipairs(player.toolList) do
        love.graphics.setColor(i == ui.toolHoveredIndex and {.8, .8, .8, 1} or {1, 1, 1, 1})
        love.graphics.draw(ui.toolsBackground, ui.toolX, winSize.y - ui.toolY - 60 * i)
    end

    for i, v in ipairs(player.toolList) do
        love.graphics.setColor(i == player.toolIndex and {1, 1, 1, 1} or {.4, .4, .4, 1})
        love.graphics.draw(v.icon, ui.toolX, winSize.y - ui.toolY - 60 * i, 0, 1/2, 1/2 )
    end
end

return ui