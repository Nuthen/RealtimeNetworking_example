host = {}

function host:init()
    self.players = {}

    self.server = socket.Server:new("*", 22122, 0)
    print('--- server ---')
    print('running on '..self.server.hostname..":"..self.server.port)

    self.peerNames = {}

    self.server:on("connect", function(data, peer)
        self:sendUserlist()
        self:sendAllPlayers(peer)
        self:addPlayer(peer)
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

        local connectId = peer.connectId
        self.peerNames[connectId] = username
        self:sendUserlist()
    end)

    self.server:on("disconnect", function(data, peer)
        local connectId = peer.connectId
        self.peerNames[connectId] = nil
        self.peerNames[connectId] = "disconnected user"
        self:sendUserlist()
    end)

    self.server:on("entityState", function(data, peer)
        local index = peer.server:index()
        local player = self.players[index]
        player.position.x = player.prevPosition.x
        player.position.y = player.prevPosition.y
        player.prevPosition.x = data.x
        player.prevPosition.y = data.y

        player.velocity.x = player.prevVelocity.x
        player.velocity.y = player.prevVelocity.y
        player.prevVelocity.x = data.vx
        player.prevVelocity.y = data.vy

        self.server:log("entityState", data.x ..' '.. data.y ..' '.. data.vx ..' '.. data.vy)
    end)

    self.timers = {}
    self.timers.userlist = 0

    self.timer = 0
    self.tick = 1/30 -- server sends 30 state packets per second
    self.tock = 0

    self.readCount = 2
end

function host:addPlayer(peer)
    local player = Player:new()
    player.peerIndex = peer.server:index()

    table.insert(self.players, player)

    self.server:emitToAll("newPlayer", {x = player.position.x, y = player.position.y, color = player.color, peerIndex = player.peerIndex})

    local peerIndex = peer.server:index()
    peer:emit("index", peerIndex)
end

function host:sendAllPlayers(peer)
    for k, player in pairs(self.players) do
        peer:emit("newPlayer", {x = player.position.x, y = player.position.y, color = player.color, peerIndex = player.peerIndex})
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

    self.server:update(dt)

    --for k, player in pairs(self.players) do
        --player:movePrediction(dt)
    --end

    if self.tock >= self.tick then
        self.tock = 0

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
            local xPos = math.floor(player.position.x*1000)/1000
            local yPos = math.floor(player.position.y*1000)/1000

            self.server:emitToAll("movePlayer", {x = xPos, y = yPos, peerIndex = player.peerIndex})
        end
    end
end

function host:draw()
    for k, player in pairs(self.players) do
        player:draw()
    end

    love.graphics.setFont(font[16])
    love.graphics.print('FPS: '..love.timer.getFPS(), 5, 5)
    love.graphics.print("Memory usage: " .. collectgarbage("count"), 5, 25)

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
        local ping = peer:round_trip_time() or -1
        love.graphics.print('Ping: '..ping, 140, 40+25*i)
    end
end
