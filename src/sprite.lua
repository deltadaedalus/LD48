local sprite = {}
sprite.__index = sprite

function sprite.new(image, r, sx, sy, ox, oy)
    local self = setmetatable({}, sprite)

    self.image = image
    self.r = r or 0
    self.sx = sx or sx
    self.sy = sy or sy
    self.ox = ox or ox
    self.oy = oy or oy

    return self
end

function sprite:draw(x, y, r, sx, sy, ox, oy)
    r = (r or 0) + self.r
    sx = (sx or 1) * self.sx
    sy = (sy or 1) * self.sy
    ox = (ox or 0) + self.ox
    oy = (oy or 0) + self.oy

    love.graphics.draw(self.image, x, y, r, sx, sy, ox, oy)
end

return sprite