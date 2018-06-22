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

-- See https://love2d.org/wiki/Config_Files for explaination
function love.conf(t)
    t.identity = "star_field"
    t.appendidentity = false
    t.version = "11.1"
    t.console = false
    t.accelerometerjoystick = false
    t.externalstorage = true
    t.gammacorrect = false
 
    t.audio.mixwithsystem = false
 
    t.window.title = "Atoiks Games - Star Field"
    t.window.icon = nil
    t.window.width = 800
    t.window.height = 600
    t.window.borderless = false
    t.window.resizable = false
    t.window.fullscreen = false
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
    t.window.msaa = 0
    t.window.display = 1
    t.window.highdpi = true
    t.window.x = nil
    t.window.y = nil
 
    t.modules.audio = true
    t.modules.data = false
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.physics = false
    t.modules.sound = true
    t.modules.system = true
    t.modules.thread = true
    t.modules.timer = true
    t.modules.touch = true
    t.modules.video = true
    t.modules.window = true
end
