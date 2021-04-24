--[[

v01-------v10
|           |
|           |
|     + <---|---- point
|           |
v01-------v11

]]
function math.bilinearInterpolate(point, v00, v10, v01, v11)
    local mx = 1 - point.x
    local t = mx * v00 + point.x * v10
    local b = mx * v01 + point.x * v11
    return (1-point.y) * t + point.y * b
end