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
        local sentTime = data.time
        self.latestServerTime = sentTime
        local difference = sentTime - self.previousTime + self.additionalTime

        self.lerpTime = difference

        local pingTime = self.client.server:last_round_trip_time() -- not sure where to use this

        for k, player in pairs(self.players) do
            if player.peerIndex == data.peerIndex then
                player:moveTo(data.x, data.y, self.lerpTime)
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

    self.verifyTick = 10000
    self.verifyTock = 0

    self.moveInput = {x = 0, y = 0}

    self.lerpTime = 1
    self.previousTime = 0
    self.latestServerTime = 0

    self.additionalTime = 0

    self.lastVerifyX = 0
    self.lastVerifyY = 0
end

function game:enter(prev, hostname, username)
    self.client.hostname = hostname
    self.client:connect()
    
    self.username = username
end

function game:quit()
    -- if game is not disconnected, the server won't remove it until the
    -- game timeouts
    self.client:disconnect()
end

function game:keypressed(key, code)
    if key == 'f1' then
        for k, player in pairs(self.players) do
            player.showRealPos = not player.showRealPos
        end
    end
    if key == 'f2' then
        for k, player in pairs(self.players) do
            if player.peerIndex == self.ownPlayerIndex then
                player:setAutono()
            end
        end
    end
    if key == 'f3' then
        for k, player in pairs(self.players) do
            if player.peerIndex == self.ownPlayerIndex then
                player.showCalcPos = not player.showCalcPos
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
    
    for k, player in pairs(self.players) do
        if player.peerIndex == self.ownPlayerIndex then -- only do an input update for your own player
            player:inputUpdate()
            player:movePrediction(dt)
        end
    end


    -- moving the client:emit code from this location is making it inaccurate, I'm not sure why

    self.additionalTime = self.additionalTime + dt

    self.tock = self.tock + dt
    if self.tock > self.tick then
        self.tock = 0
        self.client:update(dt)

        self.previousTime = self.latestServerTime -- set the previous time to whatever the latest time is, after the client updates
        self.additionalTime = 0

        -- perhaps this part should be in the timed loop, I'm just worried about player.lastTime calculated incorrectly if it's not done on the most recent frame
        for k, player in pairs(self.players) do
            if player.peerIndex == self.ownPlayerIndex then -- only do an input update for your own player
                if player.moveDir.up ~= player.prevDir.up then
                	local time = player.lastTime.up
                	time = math.floor(time * 10000) / 10000
                    self.client:emit("playerInput", {dir = "up", state = player.moveDir.up, time = time})
                end

                if player.moveDir.down ~= player.prevDir.down then
                	local time = player.lastTime.down
                	time = math.floor(time * 10000) / 10000
                    self.client:emit("playerInput", {dir = "down", state = player.moveDir.down, time = time})
                end

                if player.moveDir.left ~= player.prevDir.left then
                	local time = player.lastTime.left
                	time = math.floor(time * 10000) / 10000
                    self.client:emit("playerInput", {dir = "left", state = player.moveDir.left, time = time})
                end

                if player.moveDir.right ~= player.prevDir.right then
                	local time = player.lastTime.right
                	time = math.floor(time * 10000) / 10000
                    self.client:emit("playerInput", {dir = "right", state = player.moveDir.right, time = time})
                end

                if not player.moveDir.up and not player.moveDir.down and not player.moveDir.left and not player.moveDir.right then
                    if player.moveDir.up ~= player.prevDir.up or player.moveDir.down ~= player.prevDir.down or player.moveDir.left ~= player.prevDir.left or player.moveDir.right ~= player.prevDir.right then
                        local xPos = math.floor(player.x*1000)/1000
                        local yPos = math.floor(player.y*1000)/1000

                        self.client:emit("posVerify", {x = xPos, y = yPos})
                    end
                end

                player:resetDir()
            end
        end
    end

    --[[
    self.verifyTock = self.verifyTock + dt
    if self.verifyTock > self.verifyTick then
        self.verifyTock = 0

        for k, player in pairs(self.players) do
            if player.peerIndex == self.ownPlayerIndex then -- only do an input update for your own player
                local xPos = math.floor(player.x*1000)/1000
                local yPos = math.floor(player.y*1000)/1000

                if self.lastVerifyX ~= xPos or self.lastVerifyY ~= yPos then
                    self.client:emit("posVerify", {x = xPos, y = yPos})
                end

                self.lastVerifyX = xPos
                self.lastVerifyY = yPos
            end
        end
    end
    ]]

    for k, player in pairs(self.players) do
        if player.peerIndex ~= self.ownPlayerIndex then
            player:moveUpdate(dt)
        end
    end
end

function game:draw()
    love.graphics.setColor(255, 255, 255)

    love.graphics.print('FPS: '..love.timer.getFPS(), 300, 5)

    love.graphics.setFont(fontBold[24])
    love.graphics.print("client : " .. self.username, 5, 5)

    love.graphics.setFont(font[20])
    love.graphics.print("You are currently playing with:", 5, 40)

    for i, user in ipairs(self.users) do
        love.graphics.print(i .. ", " .. user, 5, 40+25*i)
    end

    for k, player in pairs(self.players) do
        player:draw()
    end

    love.graphics.print("You are #"..self.ownPlayerIndex, 5, 500)

    for i = 1, #self.players do
        local player = self.players[i]
        love.graphics.print('#'..player.peerIndex, 100, 40+25*i)
    end
end
