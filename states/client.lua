game = {}

inspect = require "lib.inspect"
require "entities.input"

function game:init()
    self.players = {}
    self.ownPlayerIndex = 0

    self.client = socket.Client:new("localhost", 22122, true)
    self.client.timeout = 8
    print('--- game ---')
    
    self.client:on("connect", function(data)
        self.client:emit("identify", self.username)
    end)

    self.users = {}
    self.client:on("userlist", function(data)
        self.users = data
        print(inspect(data))
    end)

    self.client:on("error", function(data)
        error(data)
    end)

    self.client:on("newPlayer", function(data)
        local player = Player:new(data.x, data.y, data.color, data.peerIndex)
        table.insert(self.players, player)
    end)

    self.client:on("index", function(data)
        self.ownPlayerIndex = data
    end)

    self.client:on("movePlayer", function(data)
        for k, player in pairs(self.players) do
            if player.peerIndex == data.peerIndex then
                if player.peerIndex ~= self.ownPlayerIndex then
                    player:setTween(data.x, data.y)
                else
                    --player.position.x = data.x
                    --player.position.y = data.y
                    player.goalX = data.x
                    player.goalY = data.y
                end
            end
        end
    end)

    self.chatting = false
    self.chatInput = Input:new(0, 0, 400, 100, font[24])
    self.chatInput:centerAround(love.graphics.getWidth()/2, love.graphics.getHeight()/2-150)
    self.chatInput.border = {127, 127, 127}

    self.timer = 0
    self.tick = 1/60
    self.tock = 0

    self.showRealPos = false

    self.readCount = 2
end

function game:enter(prev, hostname, username)
    self.client.hostname = hostname
    self.client:connect()
    
    self.username = username
end

function game:quit()
    -- if client is not disconnected, the server won't remove it until the game closes
    self.client:disconnect()
end

function game:keypressed(key, code)
    if key == 'f1' then
        self.showRealPos = not self.showRealPos
    end

    if key == 'f2' then
        for k, player in pairs(self.players) do
            if player.peerIndex == self.ownPlayerIndex then
                player:setAutono()
            end
        end
    end
end

function game:keyreleased(key, code)

end

function game:mousereleased(x, y, button)

end

function game:textinput(text)

end

function game:update(dt)
    self.timer = self.timer + dt
    self.tock = self.tock + dt
    
    for k, player in pairs(self.players) do
        if player.peerIndex == self.ownPlayerIndex then -- only do an input update for your own player
            player:inputUpdate()
            player:movePrediction(dt)
        end
    end

    self.client:update(dt)

    if self.tock >= self.tick then
        self.tock = 0

        for k, player in pairs(self.players) do
            if player.peerIndex == self.ownPlayerIndex then
                local xPos = math.floor(player.position.x*1000)/1000
                local yPos = math.floor(player.position.y*1000)/1000
                local xVel = math.floor(player.velocity.x*1000)/1000
                local yVel = math.floor(player.velocity.y*1000)/1000

                self.client:emit("entityState", {x = xPos, y = yPos, vx = xVel, vy = yVel}, "unreliable")
            end
        end
    end
end

function game:draw()
    love.graphics.setColor(255, 255, 255)

    for k, player in pairs(self.players) do
        player:draw(self.showRealPos)
    end

    love.graphics.print('FPS: '..love.timer.getFPS(), 300, 5)

    love.graphics.setFont(font[20])
    love.graphics.print("client : " .. self.username, 5, 5)

    love.graphics.print("You are currently playing with:", 5, 40)

    for i, user in ipairs(self.users) do
        love.graphics.print(i .. ". " .. user, 5, 40+25*i)
    end

    love.graphics.print("You are #"..self.ownPlayerIndex, 5, 500)

    -- print each player's name
    for i = 1, #self.players do
        local player = self.players[i]
        love.graphics.print('#'..player.peerIndex, 100, 40+25*i)
    end

    -- print the ping
    local ping = self.client.server:round_trip_time() or -1
    love.graphics.print('Ping: '.. ping .. 'ms', 140, 40+25)

    -- print the amount of data sent
    local sentData = self.client.host:total_sent_data()
    sentDataSec = sentData/self.timer
    sentData = math.floor(sentData/1000) / 1000 -- MB
    sentDataSec = math.floor(sentDataSec) / 1000 -- KB/s
    love.graphics.print('Sent Data: '.. sentData .. ' MB | ' .. sentDataSec .. ' KB/s', 5, 420)

    -- print the amount of data received
    local receivedData = self.client.host:total_received_data()
    receivedDataSec = receivedData/self.timer
    receivedData = math.floor(receivedData/1000) / 1000 -- converted to MB and rounded some
    receivedDataSec = math.floor(sentDataSec) / 1000 -- should be in KB/s
    love.graphics.print('Received Data: '.. receivedData .. ' MB | ' .. receivedDataSec .. ' KB/s', 5, 450)
end
