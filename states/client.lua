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
        local player = Player:new()
        player.x = data.x
        player.y = data.y
        player.goalX = data.x
        player.goalY = data.y
        player.calculatedX = data.x
        player.calculatedY = data.y
        player.color = data.color
        player.peerIndex = data.peerIndex
        table.insert(self.players, player)
    end)

    self.client:on("index", function(data)
        self.ownPlayerIndex = data
    end)

    self.client:on("sendTime", function(data)
        local sentTime = data
        self.latestServerTime = sentTime
        -- local difference = self.timer - sentTime -- might work better
        local difference = sentTime - self.previousTime

        self.lerpTime = difference
    end)

    self.client:on("movePlayer", function(data)
        local sentTime = data.time
        self.latestServerTime = sentTime
        -- local difference = self.timer - sentTime -- might work better
        local difference = sentTime - self.previousTime

        self.lerpTime = difference

        local pingTime = self.client.server:last_round_trip_time() -- not sure where to use this
        --self.lerpTime = self.lerpTime - math.abs(self.lerpTime - pingTime)/2 -- not over 2? too slow...

        for k, player in pairs(self.players) do
            --error(player.peerIndex..' '..data.peerIndex)

            if player.peerIndex == data.peerIndex then
                --if player.peerIndex ~= self.ownPlayerIndex then
                    --error(data.x..' '..data.y..' '..player.x..' '..player.y)
                    player:moveTo(data.x, data.y, self.lerpTime)
                --end
            end
        end
    end)

    self.client:on("calcPlayer", function(data)
        --[[
        local sentTime = data.time
        self.latestServerTime = sentTime
        -- local difference = self.timer - sentTime -- might work better
        local difference = sentTime - self.previousTime

        self.lerpTime = difference
]]
        for k, player in pairs(self.players) do
            --error(player.peerIndex..' '..data.peerIndex)

            if player.peerIndex == data.peerIndex then
                --if player.peerIndex ~= self.ownPlayerIndex then
                    --error(data.x..' '..data.y..' '..player.x..' '..player.y)
                    --player:moveTo(data.x, data.y, self.lerpTime)
                --end
                player.calculatedX = data.x
                player.calculatedY = data.y
            end
        end
    end)

    self.chatting = false
    self.chatInput = Input:new(0, 0, 400, 100, font[24])
    self.chatInput:centerAround(love.graphics.getWidth()/2, love.graphics.getHeight()/2-150)
    self.chatInput.border = {127, 127, 127}

    self.timer = 0
    self.tick = .07
    self.tock = 0

    self.moveInput = {x = 0, y = 0}

    self.lerpTime = 1
    self.previousTime = 0
    self.latestServerTime = 0
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
                player.autono = not player.autono
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

--[[
    for k, player in pairs(self.players) do
        if player.peerIndex == self.ownPlayerIndex then
            player:keypressed(key)
        end
    end
]]
end

function game:keyreleased(key, code)
    --[[
    for k, player in pairs(self.players) do
        if player.peerIndex == self.ownPlayerIndex then
            player:keyreleased(key)
        end
    end
    ]]
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

    -- perhaps this part should be in the timed loop, I'm just worried about player.lastTime calculated incorrectly if it's not done on the most recent frame
    for k, player in pairs(self.players) do
        if player.peerIndex == self.ownPlayerIndex then -- only do an input update for your own player
            if player.moveDir.up ~= player.prevDir.up then
                self.client:emit("playerInput", {dir = "up", state = player.moveDir.up, time = player.lastTime.up})
            end

            if player.moveDir.down ~= player.prevDir.down then
                self.client:emit("playerInput", {dir = "down", state = player.moveDir.down, time = player.lastTime.down})
            end

            if player.moveDir.left ~= player.prevDir.left then
                self.client:emit("playerInput", {dir = "left", state = player.moveDir.left, time = player.lastTime.left})
            end

            if player.moveDir.right ~= player.prevDir.right then
                self.client:emit("playerInput", {dir = "right", state = player.moveDir.right, time = player.lastTime.right})
            end

            player:resetDir()
        end
    end

    self.tock = self.tock + dt
    if self.tock > self.tick then
        self.tock = 0
        self.client:update(dt)

        self.previousTime = self.latestServerTime -- set the previous time to whatever the latest time is, after the client updates
    end

    for k, player in pairs(self.players) do
        if player.peerIndex ~= self.ownPlayerIndex then
            player:moveUpdate(dt)
        end
    end
end

function game:draw()
    love.graphics.setColor(255, 255, 255)

    love.graphics.setFont(fontBold[24])
    love.graphics.print("client : " .. self.username, 5, 5)

    love.graphics.setFont(font[20])
    love.graphics.print("You are currently playing with:", 5, 40)
    for i, user in pairs(self.users) do
        love.graphics.print(i .. ", " .. user, 5, 40+25*i)
    end

    for k, player in pairs(self.players) do
        player:draw()
    end
end
