Player = class('Player')

function Player:initialize()
	self.x = math.random(0, 1280)
	self.y = math.random(0, 720)

	self.width = 40
	self.height = 40

	self.color = {math.random(0, 225), math.random(0, 225), math.random(0, 225)}

	self.peerIndex = 0

	self.speed = 3

	self.hasMoved = false
end

function Player:inputUpdate()
	local dx, dy = 0, 0

	if love.keyboard.isDown('w', 'up') then
		dy = -1
	elseif love.keyboard.isDown('s', 'down') then
		dy = 1
	end

	if love.keyboard.isDown('a', 'left') then
		dx = -1
	elseif love.keyboard.isDown('d', 'right') then
		dx = 1
	end

	return dx, dy
end

function Player:move(dx, dy)
	self.x = self.x + dx * self.speed
	self.y = self.y + dy * self.speed

	if dx ~= 0 or dy ~= 0 then
		self.hasMoved = true
	end
end

function Player:draw()
	love.graphics.setColor(self.color)

	love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)
end