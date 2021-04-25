local pickup = {}
pickup.__index = pickup
setmetatable(pickup, bf.Collider)

function pickup.new(position, itemData, parentEntity)
    local self = bf.Collider.new(world, "Circle", position.x, position.y, 1)
    setmetatable(self, pickup)

    levelTerrain:addCollider(world, self, 5)
    self.itemData = itemData
    self.parentEntity = parentEntity

    return self
end

function pickup:postSolve(other)
    if (other == player.collider and #player.heldItems < player.inventorySize) then
        table.insert(player.heldItems, self.itemData)
        self.parentEntity.expired = true
        levelTerrain:removeCollider(self)
        self:destroy()
    end
end

return pickup