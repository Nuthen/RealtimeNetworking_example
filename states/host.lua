host = {}
DEBUG = true

function host:init()
    self.players = {}

	--self.server = socket.Server:new("localhost", 22122)
    self.server = socket.Server:new("*", 22122)
    print('--- server ---')
    print('running on '..self.server.hostname..":"..self.server.port)

    self.peerNames = {}

    self.server:on("connect", function(data, peer)
        self:sendUserlist()
        self:sendAllPlayers(peer)
        self:addPlayer(peer)
        local peerIndex = peer.server:index()
        peer:emit("index", peerIndex)
    end)

    self.server:on("identify", function(username, peer)
        print("IDENTIFY -------------")
        self.server:log("identify", tostring(peer) .. " identified as " .. username)

        for i, name in pairs(self.peerNames) do
            if name == username then
                peer:emit("error", "Someone with that username is already connected.")
                peer:disconnect()
                self.server:log("identify", tostring(peer) .. " identified as an already existing username.")
                return
            end
        end
        self.peerNames[peer] = username
        self:sendUserlist()
    end)

    self.server:on("disconnect", function(data, peer)
        self.peerNames[peer] = nil
        self.peerNames[peer] = "disconnected user"
        self:sendUserlist()
    end)

    self.server:on("playerInput", function(data, peer)
        local index = peer.server:index()
        self.players[index]:setInput(data.dir, data.state, data.time)

        self.server:log("playerInput", data.dir..' '.. (data.state and "true" or "false"))
    end)

    self.server:on("posVerify", function(data, peer)
        local index = peer.server:index()
        local player = self.players[index]
        player.x = data.x
        player.y = data.y

        local xPos = math.floor(player.x*1000)/1000
        local yPos = math.floor(player.y*1000)/1000
        local timeRounded = math.floor(self.timer * 10000) / 10000
        self.server:emitToAll("movePlayer", {x = xPos, y = yPos, peerIndex = player.peerIndex, time = timeRounded})

        self.server:log("posVerify", data.x..' '.. data.y)
    end)

    self.timers = {}
    self.timers.userlist = 0

    self.timer = 0
    self.tick = 1/60
    self.tock = 0

    self.readCount = 2
end

function host:addPlayer(peer)
    local player = Player:new()
    player.peerIndex = peer.server:index()

    table.insert(self.players, player)

    self.server:emitToAll("newPlayer", {x = player.x, y = player.y, color = player.color, peerIndex = player.peerIndex})
end

function host:sendAllPlayers(peer)
    for k, player in pairs(self.players) do
        peer:emit("newPlayer", {x = player.x, y = player.y, color = player.color, peerIndex = player.peerIndex})
    end
end

function host:enter()

end

function host:sendUserlist()
    local userlist = {}
    for i, name in pairs(self.peerNames) do
        table.insert(userlist, name)
    end
    self.server:emitToAll("userlist", userlist) 
end

function host:update(dt)
    self.timer = self.timer + dt

    self.tock = self.tock + dt


    for k, player in pairs(self.players) do
        player:moveBy(dt)
    end

    if self.tock > self.tick then
        self.tock = 0

        for i = 1, self.readCount do
            self.server:update(dt)
        end

        self.timers.userlist = self.timers.userlist + dt

        if self.timers.userlist > 5 then
            self.timers.userlist = 0

            for i, peer in pairs(self.server.peers) do
                if peer:state() == "disconnected" then
                    self.peerNames[peer] = nil
                end
            end
        end

        for k, player in pairs(self.players) do
            if player.hasMoved then
                player.hasMoved = false

                local xPos = math.floor(player.x*1000)/1000
                local yPos = math.floor(player.y*1000)/1000

                local xPosCalc = math.floor(player.calculatedX*1000)/1000
                local yPosCalc = math.floor(player.calculatedY*1000)/1000

                local timeRounded = math.floor(self.timer * 10000) / 10000
                self.server:emitToAll("movePlayer", {x = xPos, y = yPos, peerIndex = player.peerIndex, time = timeRounded})
            end
        end
    end
end

function host:draw()
    if DEBUG then
    	love.graphics.setFont(font[16])
    	love.graphics.print('FPS: '..love.timer.getFPS(), 5, 5)
        love.graphics.print("Memory usage: " .. collectgarbage("count")/1000 .. "MB", 5, 25)
    end

    love.graphics.print("Connected users:", 5, 40)
    local j = 1
    for i, name in pairs(self.peerNames) do
        love.graphics.print(name, 5, 40+25*j)
        j = j + 1
    end

    for i = 1, #self.players do
        local player = self.players[i]
        love.graphics.print('#'..player.peerIndex, 100, 40+25*i)
    end

    for i, peer in ipairs(self.server.peers) do
        --error(peer)
        local ping = peer:round_trip_time() or -1
        love.graphics.print('Ping: '..ping, 140, 40+25*i)
    end

    -- debug
    for k, player in pairs(self.players) do
        player:draw()
    end
end
