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

    title = love.graphics.newImage("images/title.png")

    ctrl = Ship:new(0, 0, 0)

    selected = {}
    netships = {}

    game_map = love.graphics.newCanvas(MAX_X - MIN_X, MAX_Y - MIN_Y)

    -- [[ Buttons *MUST* not overlap each other! ]]
    local font = love.graphics.newFont(14)
    btns_fire = {}
    for i = 0, 1 do
        btns_fire[i] = Button:new(10 + i * 50, ylimit + 10, love.graphics.newText(font, "Fire " .. (i + 1)), function(btn)
            for _, p in pairs(selected) do
                if p[2].team ~= ctrl.team then
                    sendFireAsCurve(i, p[1])
                end
            end
        end)
    end
    btn_trace = Button:new(110, ylimit + 10, love.graphics.newText(font, "Follow"), function(btn)
        btn:setEnabled(false)
    end)
    btn_unsel = Button:new(xlimit - 260, ylimit + 10, love.graphics.newText(font, "Unselect"), function(btn)
        unselect_selected()
    end)
    btns_overlay = { btn_trace, btn_unsel }
    for _, e in pairs(btns_fire) do
        btns_overlay[#btns_overlay + 1] = e
    end

    -- buttons related to server connection
    btns_connect = {}
    mod_on_address = true
    for i = 0, 9 do
        btns_connect[i] = Button:new(40 + i * 20, 480, love.graphics.newText(font, '' .. i), function (btn)
            if mod_on_address then
                address = address .. i
            else
                port = port .. i
            end
        end)
    end
    btns_connect['.'] = Button:new(240, 480, love.graphics.newText(font, ' . '), function (btn)
        -- Only addresses can have `.` anyway
        address = address .. '.'
    end)
    btns_connect['clr'] = Button:new(270, 480, love.graphics.newText(font, 'clear'), function (btn)
        if mod_on_address then
            address = ''
        else
            port = ''
        end
    end)
    btns_connect['address'] = Button:new(40, 504, love.graphics.newText(font, 'address'), function (btn)
        mod_on_address = true
        return btns_connect['.']:setEnabled(true)
    end)
    btns_connect['port'] = Button:new(120, 504, love.graphics.newText(font, 'port'), function (btn)
        mod_on_address = false
        return btns_connect['.']:setEnabled(false)
    end)
    btns_connect['start'] = Button:new(40, 548, love.graphics.newText(font, 'Start'), function (btn)
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
        btns_connect['address']:setEnabled(not mod_on_address)
        return btns_connect['port']:setEnabled(mod_on_address)
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
            tcp:close()
            server_selected = false
            return love.window.showMessageBox("Connection issue", status .. "\n\nBringing you back to title screen")
        end
    until not s

    local save = has_selected()
    for _, e in pairs(btns_fire) do
        e:setEnabled(save)
    end
end

function to_game_screen_coords(x, y)
    return x - 400 + ctrl.x, y - 300 + ctrl.y
end

function calculate_viewport_box(border_width)
    wp1 = border_width + 1
    del = (wp1 + 1) / 2
    return ctrl.x - 400 - del, ctrl.y - 300 - del, 800 + wp1, ylimit + wp1
end

function love.draw()
    if not server_selected then
        love.graphics.draw(title, 0, 0)
        love.graphics.print("Will connect to " .. address .. ':' .. port .. "\nUse buttons below to change server info", 40, 400)
        for _, b in pairs(btns_connect) do
            b:render()
        end
        return
    end

    love.graphics.setCanvas(game_map)
    love.graphics.push()
    love.graphics.clear()
    love.graphics.translate(-MIN_X, -MIN_Y)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', MIN_X, MIN_Y, MAX_X - MIN_X, MAX_Y - MIN_Y)
    love.graphics.setColor(0, 1, 1)
    love.graphics.rectangle('line', MIN_X, MIN_Y, MAX_X - MIN_X, MAX_Y - MIN_Y)

    -- Draw player being controlled
    love.graphics.setColor(0, 1, 1)
    ctrl:render()

    -- Draw viewport box
    love.graphics.setLineWidth(8)
    love.graphics.setColor(0, 1, 1)
    love.graphics.rectangle('line', calculate_viewport_box(8))
    love.graphics.setLineWidth(1)

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

    love.graphics.setCanvas()
    love.graphics.push()
    love.graphics.draw(game_map, 0, 0, 0, 1, 1, 400 + ctrl.x, 300 + ctrl.y)
    love.graphics.pop()

    -- Draw overlay
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.rectangle('fill', 0, ylimit, xlimit, 220)

    -- Draw buttons
    for _, btn in pairs(btns_overlay) do
        love.graphics.setColor(1, 1, 1)
        btn:render()
    end

    -- Draw minimap
    love.graphics.draw(game_map, xlimit - 160, ylimit + 2, 0, 0.095)

    -- Draw player info
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Hit points remaining: " .. math.max(0, math.ceil(ctrl.hp)), 10, 600 - 36)
    love.graphics.print(server_msg, 10, 600 - 18)
end

function click_dispatcher(btns, x, y)
    for _, e in pairs(btns) do
        if e:containsPoint(x, y) then
            return e:click()
        end
    end
end

function love.mousepressed(x, y, button, istouch)
    if not server_selected then
        click_dispatcher(btns_connect, x, y)
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
        click_dispatcher(btns_overlay, x, y)
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