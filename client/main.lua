local socket = require "socket"
require "ship"
require "button"

local ylimit = 480
local xlimit = 800

local server_selected = false

local DEFAULT_ADDR, DEFAULT_PORT = "localhost", 5000
local address, port = DEFAULT_ADDR, DEFAULT_PORT

function love.load()
    tcp = socket.tcp()
    tcp:settimeout(0)
    -- Do not connect just yet, user needs to select server address
    -- tcp:connect(address, port)

    title = love.graphics.newImage("images/title.png")

    ctrl = Ship:new(0, 0, 0)

    selected = {}
    netships = {}

    -- Buttons *MUST* not overlap each other!
    local font = love.graphics.newFont(14)
    btn_fire_1 = Button:new(10, ylimit + 10, love.graphics.newText(font, "Fire 1"), function(btn)
        for _, p in pairs(selected) do
            if p[2].team ~= ctrl.team then
                sendFireAsCurve(0, p[1])
            end
        end
    end)
    btn_fire_2 = Button:new(60, ylimit + 10, love.graphics.newText(font, "Fire 2"), function(btn)
        for _, p in pairs(selected) do
            if p[2].team ~= ctrl.team then
                sendFireAsCurve(1, p[1])
            end
        end
    end)
    btn_trace = Button:new(110, ylimit + 10, love.graphics.newText(font, "Follow"), function(btn)
        btn:setEnabled(false)
    end)
    btn_unsel = Button:new(xlimit - 80, ylimit + 10, love.graphics.newText(font, "Unselect"), function(btn)
        unselect_selected()
    end)
    buttons = { btn_fire_1, btn_fire_2, btn_trace, btn_unsel }

    -- buttons related to server connection
    btn_connect = {}
    mod_on_address = true
    for i = 0, 9 do
        btn_connect[i] = Button:new(40 + i * 20, 480, love.graphics.newText(font, '' .. i), function (btn)
            if mod_on_address then
                address = address .. i
            else
                port = port .. i
            end
        end)
    end
    btn_connect['.'] = Button:new(240, 480, love.graphics.newText(font, '.'), function (btn)
        -- Only addresses can have `.` anyway
        address = address .. '.'
    end)
    btn_connect['clr'] = Button:new(260, 480, love.graphics.newText(font, 'clr'), function (btn)
        if mod_on_address then
            address = ''
        else
            port = ''
        end
    end)
    btn_connect['address'] = Button:new(40, 504, love.graphics.newText(font, 'address'), function (btn)
        mod_on_address = true
        return btn_connect['.']:setEnabled(true)
    end)
    btn_connect['port'] = Button:new(120, 504, love.graphics.newText(font, 'port'), function (btn)
        mod_on_address = false
        return btn_connect['.']:setEnabled(false)
    end)
    btn_connect['start'] = Button:new(40, 548, love.graphics.newText(font, 'Start'), function (btn)
        local cadr = address ~= '' and address or DEFAULT_ADDR
        local cprt = port ~= '' and port or DEFAULT_PORT
        love.window.showMessageBox("Start connection", "You are about to connect to " .. cadr .. ':' .. cprt)
        tcp:connect(cadr, cprt)
        server_selected = true
    end)
end

function has_selected()
    for _, _ in pairs(selected) do
        return true
    end
    return false
end

function unselect_selected()
    for _, e in pairs(selected) do
        e[2]:unflag()
    end
    selected = {}
end

local t, updaterate = 0, 1 / 1
local server_msg = ''
function love.update(dt)
    if not server_selected then
        btn_connect['address']:setEnabled(not mod_on_address)
        return btn_connect['port']:setEnabled(mod_on_address)
    end

    t = t + dt
    if t > updaterate then
        if not btn_trace.enabled then
            local focus = selected[1]
            if focus then
                sendMoveTowards(focus[2].x, focus[2].y)
            else
                btn_trace:setEnabled(true)
            end
        end
        t = t - dt
    end

    local s, status
    repeat
        s, status = tcp:receive()
        if s then
            local cmd, id, a, b, c, msg = s:match('(.),(%d+),([+-]?%d+%.%d+),([+-]?%d+%.%d+),([+-]?%d+%.%d+),(.*)')
            if cmd ~= '@' and string.len(msg or '') > 0 then
                server_msg = os.date('[%H:%M:%S] ') .. msg
            end
            if cmd == '@' then
                local x, y, angle = tonumber(a), tonumber(b), tonumber(c)
                if id == '0' then
                    ctrl:updateXYAT(x, y, angle, msg)
                else
                    local s = netships[id] or Ship:new(0, 0, 0)
                    s:updateXYAT(x, y, angle, msg)
                    netships[id] = s
                end
            elseif cmd == 'h' then
                local hp = tonumber(a)
                if id == '0' then
                    ctrl.hp = hp
                elseif hp <= 0 then
                    netships[id] = nil
                end
            elseif cmd == '!' then
                if id == '0' then
                    tcp:close()
                    love.event.quit()
                else
                    netships[id] = nil
                end
            elseif cmd == 'r' then
                if id == '0' then
                    unselect_selected()
                    netships = { }
                else
                    netships[id] = nil
                end
            end
        elseif status == "closed" or status == "connection refused" then
            tcp:close()
            server_selected = false
            return love.window.showMessageBox("Connection issue", "Server " .. status .. "\nIs the server running?\nAre you connecting to the right server?\nIs the server already full?\n\nBringing you back to title screen")
        elseif status ~= "timeout" then
            print(status)
        end
    until not s

    local save = has_selected()
    btn_fire_1:setEnabled(save)
    btn_fire_2:setEnabled(save)
end

function to_game_screen_coords(x, y)
    return x - 400 + ctrl.x, y - 300 + ctrl.y
end

function love.draw()
    if not server_selected then
        love.graphics.draw(title, 0, 0)
        love.graphics.print("Will connect to " .. address .. ':' .. port .. "\nUse buttons below to change server info", 40, 400)
        for _, b in pairs(btn_connect) do
            b:render()
        end
        return
    end

    love.graphics.push()
    love.graphics.translate(400 - ctrl.x, 300 - ctrl.y)
    love.graphics.setColor(0, 1, 1)
    love.graphics.rectangle('line', MIN_X, MIN_Y, MAX_X - MIN_X, MAX_Y - MIN_Y)

    love.graphics.setColor(0, 1, 1)
    ctrl:render()

    for _, k in pairs(netships) do
        if k.team == nil then
            goto end_of_loop
        elseif k.team == ctrl.team then
            love.graphics.setColor(0, 0, 1)
        else
            love.graphics.setColor(1, 0, 0)
        end
        k:render()
        ::end_of_loop::
    end
    love.graphics.pop()

    -- Draw overlay
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle('fill', 0, ylimit, xlimit, 220)

    -- Draw buttons
    for _, btn in pairs(buttons) do
        love.graphics.setColor(1, 1, 1)
        btn:render()
    end

    -- Draw player info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Hit points remaining: " .. math.max(0, math.ceil(ctrl.hp)), 10, 600 - 36)
    love.graphics.print(server_msg, 10, 600 - 18)
end

function love.mousepressed(x, y, button, istouch)
    if not server_selected then
        -- Convert this to function
        for _, e in pairs(btn_connect) do
            if e:containsPoint(x, y) then
                return e:click()
            end
        end
        return
    end

    if x < xlimit and y < ylimit then
        if button == 1 then
            local clearSelected = true
            for id, e in pairs(netships) do
                if e:containsPoint(to_game_screen_coords(x, y)) then
                    clearSelected = false
                    selected[#selected + 1] = { id, e }
                    e:flag()
                end
            end
            if clearSelected then unselect_selected() end
        elseif button == 2 then
            if x < xlimit and y < ylimit then
                if not btn_trace.enabled then
                    btn_trace:setEnabled(true)
                end
                sendMoveTowards(to_game_screen_coords(x, y))
            end
        end
    else
        for _, e in pairs(buttons) do
            if e:containsPoint(x, y) then
                return e:click()
            end
        end
    end
end

function sendMoveTowards(x, y)
    local dg = string.format("@%f,%f\n", x, y)
    return tcp:send(dg)
end

function sendFireAsCurve(type, ship_id)
    local dg = string.format("f%i,%i\n", type, ship_id)
    return tcp:send(dg)
end