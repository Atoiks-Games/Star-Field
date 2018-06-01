-- [[ Creates a class ship ]]

Ship = {
    x = 0, y = 0,
    angle = 0,
    hp = 0,
    team = nil,
    flagged = false
}

MIN_X = -800
MAX_X = 800
MIN_Y = -600
MAX_Y = 600

local coords = {
    0, -16,
    -8, 8,
    8, 8,
}

function Ship:new(x, y, angle)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.x, o.y = x, y
    o.angle = angle
    o.hp = math.huge
    return o
end

function Ship:updateXYAT(x, y, angle, team)
self.x, self.y, self.angle, self.team = x, y, angle, team
end

function Ship:flag()
    self.flagged = true
end

function Ship:unflag()
    self.flagged = false
end

function Ship:containsPoint(x, y)
    return math.abs(self.x - x) < 9
       and math.abs(self.y - y) < 9
end

function Ship:render()
    love.graphics.push()
    love.graphics.translate(self.x, self.y)
    love.graphics.rotate(self.angle - math.pi / 2)

    love.graphics.polygon('fill', coords)
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon('line', coords)

    if self.flagged then
        love.graphics.setColor(1, 1, 0)
        love.graphics.circle('fill', 0, 0, 3)
    end

    return love.graphics.pop()
end

-- [[ Ignore everything above ]]

function Ship.hasPoint(x1, y1, x2, y2)
    return math.abs(x1 - x2) < 9
       and math.abs(y1 - y2) < 9
end

function Ship.weakRender(x, y, angle)
    love.graphics.push()
    love.graphics.translate(x, y)
    love.graphics.rotate(angle - math.pi / 2)

    love.graphics.polygon('fill', coords)
    love.graphics.setColor(1, 1, 1)
    love.graphics.polygon('line', coords)

    return love.graphics.pop()
end