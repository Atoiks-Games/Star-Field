--  Star-Field Client
--  Copyright (C) 2018  Atoiks-Games <atoiks-games@outlook.com>

--  This program is free software: you can redistribute it and/or modify
--  it under the terms of the GNU General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.

--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.

--  You should have received a copy of the GNU General Public License
--  along with this program.  If not, see <https://www.gnu.org/licenses/>.

-- [[ Creates a class button ]]

Button = {
    x = 0, y = 0,
    img = 0,
    listener = nil,
    enabled = true
}

function Button:new(x, y, img, listener)
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.x, o.y = x, y
    if img:typeOf("Texture") or img:typeOf("Text") or img:typeOf("Video") then
        o.img = img
    else
        error("img must be Texture or Text or Video")
    end
    o.listener = listener
    return o
end

function Button:setEnabled(k)
    self.enabled = k
end

function Button:containsPoint(x, y)
    return self.x < x
       and self.y < y
       and self.x + self.img:getWidth()  > x
       and self.y + self.img:getHeight() > y
end

function Button:setListener(f)
    self.listener = f
end

function Button:click()
    if self.enabled and self.listener then
        return self.listener(self)
    end
end

function Button:render()
    local ax, ay, aw, ah =
        self.x - 2, self.y - 2,
        self.img:getWidth() + 4, self.img:getHeight() + 4

    love.graphics.draw(self.img, self.x, self.y)
    love.graphics.setColor(1, 1, 1, self.enabled and 0.25 or 1)
    love.graphics.rectangle('fill', ax, ay, aw, ah)

    love.graphics.setColor(1, 1, 1)
    return love.graphics.rectangle('line', ax, ay, aw, ah)
end