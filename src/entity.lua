local entity = {}
entity.__index = entity

entity.all = {}
entity.acceptsInput = {}

function entity.updateAll(dt)
    for i, e in ipairs(entity.all) do
        e:update(dt)
    end
    
    --clean up expired entities
    for i = #entity.all, 1, -1 do
        if entity.all[i].expired then
            table.remove(entity.all, i)
        end
    end
end

function entity.drawAll()
    for i = #entity.all, 1, -1 do
        if (not entity.all[i].expired) then
            entity.all[i]:draw()
        end
    end
end

function entity.keypressedAll(...)
    for i, e in ipairs(entity.acceptsInput) do
        e:keypressed(...)
    end
end

function entity.mousepressedAll(...)
    for i, e in ipairs(entity.acceptsInput) do
        e:mousepressed(...)
    end
end

function entity.new()
    local self = setmetatable({}, entity)

    self.expired = false

    table.insert(entity.all, self)

    return self
end

function entity:update(dt)

end

function entity:draw()

end

function entity:mousepressed( x, y, button, istouch, presses )

end

function entity:keypressed( key, scancode, isrepeat )

end

return entity