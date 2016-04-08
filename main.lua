-- libraries
class = require 'lib.middleclass'
vector = require 'lib.vector'
state = require 'lib.state'
serialize = require 'lib.ser'
signal = require 'lib.signal'
bitser = require 'lib.bitser'
socket = require 'lib.sock'
flux = require 'lib.flux'

-- gamestates
require 'states.client'
require 'states.connect'
require 'states.host'

-- entities
require 'entities.player'

function love.load(arg)
    _font = 'assets/font/OpenSans-Regular.ttf'
    _fontBold = 'assets/font/OpenSans-Bold.ttf'
    _fontLight = 'assets/font/OpenSans-Light.ttf'

    font = setmetatable({}, {
        __index = function(t,k)
            local f = love.graphics.newFont(_font, k)
            rawset(t, k, f)
            return f
        end 
    })

    fontBold = setmetatable({}, {
        __index = function(t,k)
            local f = love.graphics.newFont(_fontBold, k)
            rawset(t, k, f)
            return f
        end
    })

    fontLight = setmetatable({}, {
        __index = function(t,k)
            local f = love.graphics.newFont(_fontLight, k)
            rawset(t, k, f)
            return f
        end 
    })
    
    love.graphics.setFont(font[14])

    state.registerEvents()

    if arg[2] == "host" then
        state.switch(host)
    else
        state.switch(connect)
    end

    math.randomseed(os.time()/10)
end

function love.keypressed(key, code)
    if key == "escape" then
        love.event.quit()
    end
end

function love.mousepressed(x, y, mbutton)
    
end

function love.textinput(text)

end

function love.resize(w, h)

end

function love.update(dt)

end

function love.draw()

end
