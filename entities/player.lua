Player = class('Player')

function Player:initialize()
	self.x = math.random(0, 1280)
	self.y = math.random(0, 720)

	self.width = 40
	self.height = 40

	self.color = {math.random(0, 225), math.random(0, 225), math.random(0, 225)}

	self.peerIndex = 0

	self.speed = 200

	self.hasMoved = false
	self.goalX = self.x
	self.goalY = self.y
	self.lerpTime = 1

	self.showRealPos = false
end

function Player:inputUpdate(dt)
	local dx, dy = 0, 0

	if love.keyboard.isDown('w', 'up') then
		dy = -dt
	elseif love.keyboard.isDown('s', 'down') then
		dy = dt
	end

	if love.keyboard.isDown('a', 'left') then
		dx = -dt
	elseif love.keyboard.isDown('d', 'right') then
		dx = dt
	end

	self:move(dx, dy)

	return dx, dy
end

function Player:move(dx, dy)
	self.x = self.x + dx * self.speed
	self.y = self.y + dy * self.speed

	if dx ~= 0 or dy ~= 0 then
		self.hasMoved = true
	end
end

function Player:moveTo(x, y, lerp)
	self.goalX = x
	self.goalY = y
	self.lerpTime = lerp
end

function Player:moveUpdate(dt)
	--error(self.lerpTime..' '..(self.x - self.goalX)..' '..self.x..' '..self.goalX)
	self.x = self.x + (self.goalX - self.x)/self.lerpTime * dt
	self.y = self.y + (self.goalY - self.y)/self.lerpTime * dt
end

function Player:draw()
	love.graphics.setColor(self.color)

	love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)

	if self.showRealPos then
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.rectangle('fill', self.goalX, self.goalY, self.width, self.height)
	end
end