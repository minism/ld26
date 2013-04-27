require 'math'

require 'assets'
require 'sprite'
require 'input'
require 'player'
require 'entity'
require 'block'

game = leaf.Context()


--
-- Game constants
--

BLOCK_SIZE = 16
WORLD_BLOCKS_X = 8
WORLD_BLOCKS_Y = 12
WORLD_W = BLOCK_SIZE * WORLD_BLOCKS_X
WORLD_H = BLOCK_SIZE * WORLD_BLOCKS_Y
CAMERA_SCALE = 3
SCREEN_W = 600 / CAMERA_SCALE
SCREEN_H = 800 / CAMERA_SCALE
BLOCK_TIMER = 1
GRAVITY = 300



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
    self.entities = {}
    self.blocks = {}
    for i=1, WORLD_BLOCKS_X do
        self.blocks[i] = {}
    end

    self:queueBlock()
    time:every(0.75, function() self:queueBlock() end)
end




--
-- Control
--
function game:addEntity(entity)
    table.insert(self.entities, entity)
end


function game:queueBlock(data)
    local data = data or {}
    local pos = data.pos or math.random(1, WORLD_BLOCKS_X)
    local x = BLOCK_SIZE * (pos - 1)

    -- Create block hitn 
    local highest_block = game:getHighestBlock(pos)
    local hint_y = highest_block and highest_block.y - BLOCK_SIZE or WORLD_H - BLOCK_SIZE
    local blockHint = BlockHint {
        life = BLOCK_TIMER,
        x = x,
        y = hint_y,
    }
    self:addEntity(blockHint)

    -- Queue block
    time:after(BLOCK_TIMER, function() 
        local block = Block {
            x = x,
            y = 0,
        }
        self:addEntity(block)
    end)
end


function game:getHighestBlock(column)
    for row=1, WORLD_BLOCKS_Y do
        if self.blocks[column][row] ~= nil then
            return self.blocks[column][row]
        end
    end
end



--
-- Event handling
--

function game:trigger(event, ...)
    if self['evt_' .. event] ~= nil then
        self['evt_' .. event](self, ...)
    end
end

function game:evt_block_land(block, target)
    -- Freeze block and add to index
    block.awake = false
    local new_x, new_y = snap_floor(block.x, BLOCK_SIZE), nil
    if target then
        new_y = target.y - BLOCK_SIZE
    else
        new_y = snap_floor(block.y, BLOCK_SIZE)
    end
    block.x, block.y = new_x, new_y
    local col, row = block.x / BLOCK_SIZE + 1, block.y / BLOCK_SIZE + 1
    self.blocks[col][row] = block
end



-- 
-- Logic
--


function game:update(dt)
    time:update(dt)

    -- Prune dead entities
    remove_if(self.entities, function(entity) 
        return entity.alive == false
    end)

    -- Update entities
    for i, entity in ipairs(self.entities) do
        entity:update(dt)
    end
end


function game:keypressed(key, unicode)

end





--
-- Rendition
--
function game:draw()
    -- Draw in scale
    lg.push()
        lg.scale(CAMERA_SCALE, CAMERA_SCALE)
        -- Draw a frame
        sprite.drawBackground(1, 0, 0)

        -- Center world drawing
        lg.translate((SCREEN_W - WORLD_W) / 2, (SCREEN_H - WORLD_H) / 2)
        self:drawWorld()
    lg.pop()

    self:drawHUD()
end


function game:drawWorld()
    -- Draw level background
    sprite.drawWorldBackground(2, 0, 0, 0)

    -- Draw entities
    for i, entity in ipairs(self.entities) do
        entity:draw()
    end
end


function game:drawHUD()
    if self.flags.debug then
        lg.print("FPS: " .. love.timer.getFPS(), 5, 5)
        lg.print("#Timers: " .. #time.timers, 5, 15)
        console:drawLog()
    end
end

