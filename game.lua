require 'assets'
require 'sprite'
require 'input'
require 'player'
require 'entity'

game = leaf.Context()


--
-- Game constants
--

BLOCK_SIZE = 16
WORLD_BLOCKS_X = 8
WORLD_BLOCKS_Y = 12
WORLD_X = BLOCK_SIZE * WORLD_BLOCKS_X
WORLD_Y = BLOCK_SIZE * WORLD_BLOCKS_Y
CAMERA_SCALE = 3
SCREEN_X = 600 / CAMERA_SCALE
SCREEN_Y = 800 / CAMERA_SCALE


--
-- Initialization
--
function game:init()
    -- Load all assets
    assets.load()
    sprite.load()


    -- Runtime state flags
    self.flags = {
        debug = true,
    }


    -- Setup main game data
    self.camera = Camera()
    self.entities = {}
end





--
-- Rendition
--
function game:draw()
    -- Draw in scale
    lg.push()
        lg.scale(CAMERA_SCALE, CAMERA_SCALE)

        -- Center the game
        lg.translate((SCREEN_X - WORLD_X) / 2, (SCREEN_Y - WORLD_Y) / 2)
        self:drawStatic()
        self:drawEntities()
    lg.pop()

    self:drawHUD()
end


function game:drawStatic()
    -- World frame
    lg.rectangle('line', 0, 0, WORLD_X, WORLD_Y)
    -- local quad = lg.newQuad(0, 0, 16, 16, 128, 128)
    sprite.drawSprite(1, 0, 0)
    -- lg.drawq(assets.gfx.sheet1, quad, 0, 0)
    -- lg.draw(assets.gfx.sheet1, 0, 0)

    -- Draw blocks
end



function game:drawEntities()

end


function game:drawHUD()
    if self.flags.debug then
        console:drawLog()
    end
end



-- 
-- Logic
--


function game:update(dt)

end


function game:keypressed(key, unicode)

end

