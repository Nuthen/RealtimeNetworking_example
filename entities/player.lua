Player = class('Player')

function Player:initialize(x, y, color, peerIndex)
	local x, y = x or math.random(0, love.graphics.getWidth()), y or math.random(0, love.graphics.getHeight())
	self.position = vector(x, y)
	self.prevPosition = vector(x, y)

	self.velocity = vector(0, 0)
	self.prevVelocity = vector(0, 0)
	self.width = 40
	self.height = 40
	self.speed = 280
	self.color = color or {math.random(0, 225), math.random(0, 225), math.random(0, 225)}

	-- this is the goal position to be tweened towards
	-- on the client, it slowly moves it to where the server says it should be
	self.goalX = self.position.x
	self.goalY = self.position.y

	self.showRealPos = false
	self.autono = false

	self.rotateX = 0
	self.rotateY = 0

	self.circleSize = math.random(5, 15)

	-- this is the value of a player in the array of players, as determined by the server
	-- there is an issue with peerIndex and disconnect
	self.peerIndex = peerIndex or 0

	self.lerpTween = nil -- stores the tween for interpolation of a non-client player
end

-- client function to enable autonomous movement
function Player:setAutono()
	self.autono = not self.autono

	self.rotateX = self.position.x
	self.rotateY = self.position.y
end

-- used by client
function Player:inputUpdate(dt)
	self.velocity.x, self.velocity.y = 0, 0

	if self.autono then
		local dx = math.cos(game.timer * self.circleSize)
		local dy = math.sin(game.timer * self.circleSize)

		self.velocity.x = dx * self.speed
		self.velocity.y = dy * self.speed
	end

	if love.keyboard.isDown('w', 'up')    then self.velocity.y = -self.speed end
	if love.keyboard.isDown('s', 'down')  then self.velocity.y =  self.speed end
	if love.keyboard.isDown('a', 'left')  then self.velocity.x = -self.speed end
	if love.keyboard.isDown('d', 'right') then self.velocity.x =  self.speed end

	if self.velocity.x ~= 0 and self.velocity.y ~= 0 then -- diagonal movement is multipled to be the same overall speed
		self.velocity.x, self.velocity.y = self.velocity.x * 0.70710678118, self.velocity.y * 0.70710678118
	end
end

-- used by the client to set the interpolation tween
-- the player will move towards the specified location
function Player:setTween(goalX, goalY)
	self.goalX = goalX
	self.goalY = goalY

	if self.lerpTween then
		self.lerpTween:stop()
	end

	local dist = vector(goalX - self.position.x, goalY - self.position.y):len()
	local time = dist / self.speed

	self.lerpTween = flux.to(self.position, time, {x = goalX, y = goalY})
end

-- used by the client for only the local player. The client can predict where his 
-- used by the server to predict player movement - dead-reckoning
function Player:movePrediction(dt)
	self.position.x = self.position.x + self.velocity.x * dt
	self.position.y = self.position.y + self.velocity.y * dt
end

function Player:draw(showRealPos)
	showRealPos = showRealPos or false

	love.graphics.setColor(self.color)

	love.graphics.rectangle('fill', self.position.x, self.position.y, self.width, self.height)

	if showRealPos then
		love.graphics.setColor(255, 0, 0, 165)
		love.graphics.rectangle('fill', self.goalX, self.goalY, self.width, self.height)
	end
	love.graphics.setColor(255, 255, 255)
end