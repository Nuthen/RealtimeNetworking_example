host = {}

function host:init()
    self.players = {}
    self.enemies = {}

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

        local connectId = peer.server:index()-- self.server:getClient(peer).connectId
        self.peerNames[connectId] = username
        self:sendUserlist()
    end)

    self.server:on("disconnect", function(data, peer)
        local connectId = peer.server:index() -- self.server:getClient(peer).connectId
        self.peerNames[connectId] = nil
        self.peerNames[connectId] = "disconnected user"
        self:sendUserlist()
    end)

    self.server:on("entityState", function(data, peer)
        local connectId = peer.server:index() -- self.server:getClient(peer).connectId
        local player = self.players[connectId]
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

    self.server:on("addEnemy", function(data, peer)
        if #self.enemies < self.enemyMax then
            local enemy = Enemy:new()
            table.insert(self.enemies, enemy)
            local index = #self.enemies

            self.server:emitToAll("newEnemy", {x = enemy.position.x, y = enemy.position.y, color = enemy.color, index = index})
        end
        self.server:log("addEnemy", index)
    end)

    self.timers = {}
    self.timers.userlist = 0

    self.timer = 0
    self.tick = 1/30 -- server sends 30 state packets per second
    self.tock = 0

    self.enemyMax = 15

    self.readCount = 2
end

function host:addPlayer(peer)
    local connectId = peer.server:index() -- self.server:getClient(peer).connectId
    local player = Player:new()

    table.insert(self.players, connectId, player) -- changed here to debug

    self.server:emitToAll("newPlayer", {x = player.position.x, y = player.position.y, color = player.color, index = connectId}) -- changed here to debug

    peer:emit("index", peer.server:index()) -- changed here to debug
end

function host:sendAllPlayers(peer)
    for k, player in pairs(self.players) do
        peer:emit("newPlayer", {x = player.position.x, y = player.position.y, color = player.color, index = k})
    end
end

function host:enter()

end

function host:sendUserlist()
    local userlist = {}
    for k, name in pairs(self.peerNames) do
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

            for k, peer in pairs(self.server.peers) do
                if peer:state() == "disconnected" then
                    self.peerNames[peer] = nil
                end
            end
        end

        for k, player in pairs(self.players) do
            local xPos = math.floor(player.position.x*1000)/1000
            local yPos = math.floor(player.position.y*1000)/1000

            self.server:emitToAll("movePlayer", {x = xPos, y = yPos, index = k})
        end

        for k, enemy in pairs(self.enemies) do
            local xPos = math.floor(enemy.position.x*1000)/1000
            local yPos = math.floor(enemy.position.y*1000)/1000

            self.server:emitToAll("moveEnemy", {x = xPos, y = yPos, index = k})
        end
    end

    for k, enemy in pairs(self.enemies) do
        enemy:update(dt, self.timer)
    end
end

function host:draw()
    for k, player in pairs(self.players) do
        player:draw()
    end

    for k, enemy in pairs(self.enemies) do
        enemy:draw()
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

    local j = 1
    for k, player in pairs(self.players) do
        love.graphics.print('#'..k, 100, 40+25*j)
        j = j + 1
    end

    for i, peer in ipairs(self.server.peers) do
        local ping = peer:round_trip_time() or -1
        love.graphics.print('Ping: '..ping, 140, 40+25*i)
    end

    -- print the amount of data sent
    local sentData = self.server.host:total_sent_data()
    sentDataSec = sentData/self.timer
    sentData = math.floor(sentData/1000) / 1000 -- MB
    sentDataSec = math.floor(sentDataSec/10) / 100 -- KB/s
    love.graphics.print('Sent Data: '.. sentData .. ' MB', 46, 420)
    love.graphics.print('| ' .. sentDataSec .. ' KB/s', 250, 420)

    local packetsSentSec = packetsSent / self.timer
    packetsSentSec = math.floor(packetsSentSec*10000)/10000
    love.graphics.print('Sent Packets: '.. packetsSent, 370, 420)
    love.graphics.print('| ' .. packetsSentSec .. ' packet/s', 574, 420)

    -- print the amount of data received
    local receivedData = self.server.host:total_received_data()
    receivedDataSec = receivedData/self.timer
    receivedData = math.floor(receivedData/1000) / 1000 -- converted to MB and rounded some
    receivedDataSec = math.floor(receivedDataSec/10) / 100 -- should be in KB/s
    love.graphics.print('Received Data: '.. receivedData .. ' MB', 5, 450)
    love.graphics.print('| ' .. receivedDataSec .. ' KB/s', 250, 450)

    local packetsReceivedSec = packetsReceived / self.timer
    packetsReceivedSec = math.floor(packetsReceivedSec*10000)/10000
    love.graphics.print('Received Packets: '.. packetsReceived, 370, 450)
    love.graphics.print('| ' .. packetsReceivedSec .. ' packet/s', 574, 450)

    love.graphics.print("Enemies: " .. #self.enemies, 400, 25)
end
