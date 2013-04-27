require 'math'
require 'os'

tween = require 'lib.tween'
_ = require 'lib.underscore'
inspect = require 'lib.inspect'
require 'leaf'


-- Alias everything from leaf directly
require 'leaf'
for k, v in pairs(leaf) do
    _G[k] = v
end


require 'utils'


-- Other aliases
lg = love.graphics

-- Singletons
app = App()
console = Console()
time = Time()
colors = require 'colors'


function love.load()
    -- Seed randomness
    math.randomseed(os.time()); math.random()

    require 'game'
    app:bind()
    app:pushContext(game)
    game:init()
end

