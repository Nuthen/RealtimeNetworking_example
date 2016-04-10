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
	self.autono = false

	self.circleSize = math.random(5, 15)

	self.prevDir = {up = false, down = false, left = false, right = false}
	self.moveDir = {up = false, down = false, left = false, right = false}

	self.lastTime = {up = 0, down = 0, left = 0, right = 0}
	self.moveTime = {up = 0, down = 0, left = 0, right = 0}

	self.calculatedX = self.x
	self.calculatedY = self.y
	self.showCalcPos = false
end

-- used by client
function Player:inputUpdate(dt)
--[[
	local dx, dy = 0, 0

	if self.autono then
		dx = math.sin(game.timer*self.circleSize) * dt
		dy = math.cos(game.timer*self.circleSize) * dt
	else
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
	end

	self:move(dx, dy)

	return dx, dy
]]

	if self.autono then
		if math.sin(game.timer * self.circleSize) >= 0 then
			self.moveDir.right = true
			self.moveDir.left = false
		else
			self.moveDir.right = false
			self.moveDir.left = true
		end
		if math.cos(game.timer * self.circleSize) >= 0 then
			self.moveDir.down = true
			self.moveDir.up = false
		else
			self.moveDir.down = false
			self.moveDir.up = true
		end
	else
		if love.keyboard.isDown('w', 'up') then self.moveDir.up = true else self.moveDir.up = false end
		if love.keyboard.isDown('s', 'down') then self.moveDir.down = true else self.moveDir.down = false end
		if love.keyboard.isDown('a', 'left') then self.moveDir.left = true else self.moveDir.left = false end
		if love.keyboard.isDown('d', 'right') then self.moveDir.right = true else self.moveDir.right = false end

		if self.moveDir.up ~= self.prevDir.up then
			local diff = game.timer - self.lastTime.up
            self.lastTime.up = game.timer
            --self:moveActual('up', diff)
        end

        if self.moveDir.down ~= self.prevDir.down then
			local diff = game.timer - self.lastTime.down
            self.lastTime.down = game.timer
            --self:moveActual('down', diff)
        end

        if self.moveDir.left ~= self.prevDir.left then
			local diff = game.timer - self.lastTime.left
			self.lastTime.left = game.timer
            --self:moveActual('left', diff)
		end

        if self.moveDir.right ~= self.prevDir.right then
			local diff = game.timer - self.lastTime.right
           	self.lastTime.right = game.timer
            --self:moveActual('right', diff)
        end
	end
end

function Player:setInput(dir, state, time)
	if dir == 'up' then
		self.moveDir.up = state
		if state then
			self.lastTime.up = time
		else
			local diff = time - self.lastTime.up
			self.moveTime.up = diff
			self:moveActual('up', diff)
		end
	end
	if dir == 'down' then
		self.moveDir.down = state
		if state then
			self.lastTime.down = time
		else
			local diff = time - self.lastTime.down
			self.moveTime.down = diff
			self:moveActual('down', diff)
		end
	end
	if dir == 'left' then
		self.moveDir.left = state
		if state then
			self.lastTime.left = time
		else
			local diff = time - self.lastTime.left
			self.moveTime.left = diff
			self:moveActual('left', diff)
		end
	end
	if dir == 'right' then
		self.moveDir.right = state
		if state then
			self.lastTime.right = time
		else
			local diff = time - self.lastTime.right
			self.moveTime.right = diff
			self:moveActual('right', diff)
		end
	end
end

function Player:moveActual(dir, diff)
	dx, dy = 0, 0
	if dir == 'up' then
		dy = dy - diff
	end
	if dir == 'down' then
		dy = dy + diff
	end
	if dir == 'left' then
		dx = dx - diff
	end
	if dir == 'right' then
		dx = dx + diff
	end

	self.calculatedX = self.calculatedX + dx * self.speed
	self.calculatedY = self.calculatedY + dy * self.speed

	-- this is an important step
	if dx < -.00001 or dx > .00001 then -- check if it is basically not 0 (floating points can be weird)
		self.x = self.calculatedX
	end
	if dy < -.00001 or dy > .00001 then
		self.y = self.calculatedY
	end
end

function Player:resetDir()
	self.prevDir.up = self.moveDir.up
	self.prevDir.down = self.moveDir.down
	self.prevDir.left = self.moveDir.left
	self.prevDir.right = self.moveDir.right
end

function Player:keypressed(key)
	if key == 'w' or key == 'up' then
		self.moveDir.up = true
	end
	if key == 's' or key == 'down' then
		self.moveDir.down = true
	end
	if key == 'a' or key == 'left' then
		self.moveDir.left = true
	end
	if key == 'd' or key == 'right' then
		self.moveDir.right = true
	end
end

function Player:keyreleased(key)
	if key == 'w' or key == 'up' then
		self.moveDir.up = false
	end
	if key == 's' or key == 'down' then
		self.moveDir.down = false
	end
	if key == 'a' or key == 'left' then
		self.moveDir.left = false
	end
	if key == 'd' or key == 'right' then
		self.moveDir.right = false
	end
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

function Player:movePrediction(dt)
	local dx, dy = 0, 0

	if self.moveDir.up then
		dy = dy - self.speed * dt
	end
	if self.moveDir.down then
		dy = dy + self.speed * dt
	end

	if self.moveDir.left then
		dx = dx - self.speed * dt
	end
	if self.moveDir.right then
		dx = dx + self.speed * dt
	end

	self.x = self.x + dx
	self.y = self.y + dy
end

function Player:moveBy(dt)
	local dx, dy = 0, 0
	local overprediction = .8

	if self.moveDir.up then
		dy = dy - self.speed * dt * overprediction
	end
	if self.moveDir.down then
		dy = dy + self.speed * dt * overprediction
	end

	if self.moveDir.left then
		dx = dx - self.speed * dt * overprediction
	end
	if self.moveDir.right then
		dx = dx + self.speed * dt * overprediction
	end

	self.x = self.x + dx
	self.y = self.y + dy

	if dx ~= 0 or dy ~= 0 then
		self.hasMoved = true
	end
end

function Player:draw()
	love.graphics.setColor(self.color)

	love.graphics.rectangle('fill', self.x, self.y, self.width, self.height)

	if self.showRealPos then
		love.graphics.setColor(255, 0, 0, 255)
		love.graphics.rectangle('fill', self.goalX, self.goalY, self.width, self.height)
	end

	if self.showCalcPos then
		love.graphics.setColor(255, 255, 255, 255)
		love.graphics.rectangle('fill', self.calculatedX, self.calculatedY, self.width, self.height)
	end

	love.graphics.setColor(255, 255, 255)

	local i = 100

	love.graphics.print("up prev".." ".. (self.prevDir.up and "true" or "false"), 5, i)
	i = i + 35
	love.graphics.print("down prev".." ".. (self.prevDir.down and "true" or "false"), 5, i)
	i = i + 35
	love.graphics.print("left prev".." ".. (self.prevDir.left and "true" or "false"), 5, i)
	i = i + 35
	love.graphics.print("right prev".." ".. (self.prevDir.right and "true" or "false"), 5, i)
	i = i + 35

	love.graphics.print("up move".." ".. (self.moveDir.up and "true" or "false"), 5, i)
	i = i + 35
	love.graphics.print("down move".." ".. (self.moveDir.down and "true" or "false"), 5, i)
	i = i + 35
	love.graphics.print("left move".." ".. (self.moveDir.left and "true" or "false"), 5, i)
	i = i + 35
	love.graphics.print("right move".." ".. (self.moveDir.right and "true" or "false"), 5, i)
	i = i + 35
end