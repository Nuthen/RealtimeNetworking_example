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
        player.color = data.color
        player.peerIndex = data.peerIndex
        table.insert(self.players, player)
    end)

    self.client:on("index", function(data)
        self.ownPlayerIndex = data
    end)

    self.client:on("movePlayer", function(data)
        for k, player in pairs(self.players) do
            --error(player.peerIndex..' '..data.peerIndex)
            if player.peerIndex == data.peerIndex then
                --error(data.x..' '..data.y..' '..player.x..' '..player.y)
                player.x = data.x
                player.y = data.y
            end
        end
    end)

    self.chatting = false
    self.chatInput = Input:new(0, 0, 400, 100, font[24])
    self.chatInput:centerAround(love.graphics.getWidth()/2, love.graphics.getHeight()/2-150)
    self.chatInput.border = {127, 127, 127}
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

end

function game:keyreleased(key, code)

end

function game:mousereleased(x, y, button)

end

function game:textinput(text)
end

function game:update(dt)
    self.client:update(dt)

    for k, player in pairs(self.players) do
        if player.peerIndex == self.ownPlayerIndex then -- only do an input update for your own player
            dx, dy = player:inputUpdate()
            if dx ~= 0 or dy ~= 0 then
                self.client:emit("movePlayer", {x = dx, y = dy})
            end
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
