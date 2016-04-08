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
end

function game:keyreleased(key, code)

end

function game:mousereleased(x, y, button)

end

function game:textinput(text)
end

function game:update(dt)
    flux.update(dt)

    self.timer = self.timer + dt
    
    for k, player in pairs(self.players) do
        if player.peerIndex == self.ownPlayerIndex then -- only do an input update for your own player
            dx, dy = player:inputUpdate(dt)
            self.moveInput.x = self.moveInput.x + dx
            self.moveInput.y = self.moveInput.y + dy
        end
    end

    self.tock = self.tock + dt
    if self.tock > self.tick then
        self.tock = 0
        self.client:update(dt)

        self.previousTime = self.latestServerTime -- set the previous time to whatever the latest time is, after the client updates

        for k, player in pairs(self.players) do
            if player.peerIndex == self.ownPlayerIndex then -- only do an input update for your own player
                if self.moveInput.x ~= 0 or self.moveInput.y ~= 0 then
                    self.client:emit("movePlayer", {x = self.moveInput.x, y = self.moveInput.y})

                    self.moveInput.x = 0
                    self.moveInput.y = 0
                end
            end
        end
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
