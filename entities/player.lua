Player = class('Player')

function Player:initialize(x, y, color, peerIndex)
	self.x = x or math.random(0, love.graphics.getWidth())
	self.y = y or math.random(0, love.graphics.getHeight())

	-- this is the goal position to be tweened towards
	-- on the client, it slowly moves it to where the server says it should be
	-- on the server, it moves towards where it knows it should be to prevent jumpiness
	self.goalX = self.x
	self.goalY = self.y

	-- this is the calculated, accurate value for position based on keypress and keyrelease
	-- it's very accurate, but it's never guarenteed when it will be calculated, because someone could hold a key down forever
	self.calculatedX = self.x
	self.calculatedY = self.y

	self.color = color or {math.random(0, 225), math.random(0, 225), math.random(0, 225)}

	-- this is the value of a player in the array of players, as determined by the server
	-- there is an issue with peerIndex and disconnect
	self.peerIndex = peerIndex or 0

	self.width = 40
	self.height = 40

	self.speed = 200

	self.hasMoved = false
	self.lerpTime = 1

	self.showRealPos = false
	self.autono = false

	self.circleSize = math.random(5, 15)

	-- boolean for each direction, if you are moving in a given direction or not
	self.prevDir = {up = false, down = false, left = false, right = false} -- result of the previous frame
	self.moveDir = {up = false, down = false, left = false, right = false} -- result of the current frame

	self.lastTime = {up = 0, down = 0, left = 0, right = 0}
	self.moveTime = {up = 0, down = 0, left = 0, right = 0}

	self.showCalcPos = false

	-- difference in predictions
	self.xDiff = 0
	self.yDiff = 0
	self.timeBehind = 0
	self.timeDifferenceX = 0
	self.timeDifferenceY = 0
end

function Player:setAutono()
	self.autono = not self.autono

	--self.prevDir = {up = false, down = false, left = false, right = false}
	self.moveDir = {up = false, down = false, left = false, right = false}
end

-- used by client
function Player:inputUpdate(dt)
	if self.autono then
		--self.prevDir = {up = false, down = false, left = false, right = false}
		self.moveDir = {up = false, down = false, left = false, right = false}

		local dx = math.sin(game.timer * self.circleSize)
		local dy = math.cos(game.timer * self.circleSize)

		if dx >= .1 then
			self.moveDir.right = true
			self.moveDir.left = false
		elseif dx <= .1 then
			self.moveDir.right = false
			self.moveDir.left = true
		end
		if dy >= .1 then
			self.moveDir.down = true
			self.moveDir.up = false
		elseif dy <= .1 then
			self.moveDir.down = false
			self.moveDir.up = true
		end
	else
		if love.keyboard.isDown('w', 'up') then self.moveDir.up = true else self.moveDir.up = false end
		if love.keyboard.isDown('s', 'down') then self.moveDir.down = true else self.moveDir.down = false end
		if love.keyboard.isDown('a', 'left') then self.moveDir.left = true else self.moveDir.left = false end
		if love.keyboard.isDown('d', 'right') then self.moveDir.right = true else self.moveDir.right = false end

		
	end

	-- moved outside so that autonomous movement can utilize it as well
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

-- used by the server
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
		self.xDiff = self.calculatedX - self.x
		self.goalX = self.calculatedX
		self.timeDifferenceX = math.abs(self.xDiff) / self.speed -- perhaps this should not be added to the previous?
		self.x = self.calculatedX -- this line is iffy
	end
	if dy < -.00001 or dy > .00001 then
		self.yDiff = self.calculatedY - self.y
		self.goalY = self.calculatedY
		self.timeDifferenceY = math.abs(self.yDiff) / self.speed
		self.y = self.calculatedY -- this line is iffy
	end
end

function Player:resetDir()
	self.prevDir.up = self.moveDir.up
	self.prevDir.down = self.moveDir.down
	self.prevDir.left = self.moveDir.left
	self.prevDir.right = self.moveDir.right
end

-- used by the server
function Player:move(dx, dy)
	self.x = self.x + dx * self.speed
	self.y = self.y + dy * self.speed

	if dx ~= 0 or dy ~= 0 then
		self.hasMoved = true
	end
end

-- used by the client to set the interpolation
function Player:moveTo(x, y, lerp)
	self.goalX = x
	self.goalY = y
	self.lerpTime = lerp
end

function Player:moveUpdate(dt)
	if self.lerpTime == 0 then self.lerpTime = 0.000001 end -- avoid the divide by zero if it happens!
	local dx, dy = (self.goalX - self.x)/self.lerpTime * dt, (self.goalY - self.y)/self.lerpTime * dt
	local velocity = vector(dx, dy)

	if velocity:len() >= self.speed * dt then -- if the distance it's trying to move is greater than the distance it should be allowed to move, then limit it
		velocity = velocity:normalized() * self.speed * dt
		dx, dy = velocity:unpack()
	end

	self.x = self.x + dx
	self.y = self.y + dy
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
	--local overprediction = .7 -- this should probably not be used, it was just used for guessing
	local overprediction = 1

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


	-- the player moves in a very jumpy way. the goal of this part is to smooth that jumpiness
	-- note that the time is seperate for each axis, I'm not sure if that's correct to do
	-- for some reason, this makes the "Red box" inaccurate
	--[[
	if self.timeDifferenceX > 0 then
		dx = dx + (self.goalX - (self.x))/self.timeDifferenceX * dt
		self.timeDifferenceX = math.max(0, self.timeDifferenceX - dt)
	end

	if self.timeDifferenceY > 0 then
		dy = dy + (self.goalY - (self.y))/self.timeDifferenceY * dt
		self.timeDifferenceY = math.max(0, self.timeDifferenceY - dt)
	end

	-- does this help much?
	--dx = math.min(dx, self.speed*dt)
	--dy = math.min(dy, self.speed*dt)
	]]
	--

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

	--[[
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
	]]
end