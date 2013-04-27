require 'math'

require 'assets'
require 'sprite'
require 'input'
require 'player'
require 'entity'
require 'block'
require 'input'

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
BLOCK_TIMER = 0.5
GRAVITY = 300
MOVE_SPEED = 60
JUMP_POWER = 150

LEFT, TOP, RIGHT, BOTTOM = 0, 1, 2, 3



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
        showbb = false,
    }

    game:initWorld()
end


function game:initWorld()
    time:empty()

    -- Setup main game data
    self.entities = {}
    self:setStaticBlocks()

    -- Position player
    player:reset()
    player.x = 0
    player.y = WORLD_H - player.h

    -- DEBUG
    -- self:queueBlock({pos=1})
    self:queueBlock()
    time:every(BLOCK_TIMER, function() self:queueBlock() end)
end



-- Insert static border blocks for world edge collision
function game:setStaticBlocks()
    for i=-1, WORLD_BLOCKS_X do
        local static_block_top = PhysEntity {
            x=i*BLOCK_SIZE,
            y=-BLOCK_SIZE,
            awake = false,
        }
        local static_block_bot = PhysEntity {
            x=i*BLOCK_SIZE,
            y=WORLD_H,
            awake = false,
        }
        game:addEntity(static_block_top)
        game:addEntity(static_block_bot)
    end
    for i=-1, WORLD_BLOCKS_Y do
        local static_block_top = PhysEntity {
            y=i*BLOCK_SIZE,
            x=-BLOCK_SIZE,
            awake = false,
        }
        local static_block_bot = PhysEntity {
            y=i*BLOCK_SIZE,
            x=WORLD_W,
            awake = false,
        }
        game:addEntity(static_block_top)
        game:addEntity(static_block_bot)
    end
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
    local x = (column - 1) * BLOCK_SIZE + 1
    for row=0, WORLD_BLOCKS_Y-1 do
        local y = row*BLOCK_SIZE
        for i, entity in ipairs(self.entities) do
            if entity.block and entity.grounded then
                local a,b,c,d = entity:getbb()
                if rect.contains(a,b,c,d,x,y) then
                    return entity
                end
            end
        end
    end
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

    player:update(dt)
end

function game:keypressed(key, unicode)
    if input.match('debug', key) then
        self.flags.debug = not self.flags.debug
    end
    if input.match('showbb', key) then
        self.flags.showbb = not self.flags.showbb
    end
    if input.match('init', key) then
        game:initWorld()
    end
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
    sprite.drawWorldBackground(2, 0, 0)

    -- Draw entities sorted by z index
    for z=0, 3 do
        for i, entity in ipairs(self.entities) do
            if entity.z_index == z then
                entity:draw()
            end
        end
    end
    
    player:draw()
end


function game:drawHUD()    
    colors.white()
    if self.flags.debug then
        lg.print("FPS: " .. love.timer.getFPS(), 5, 5)
        lg.print("#Timers: " .. #time.timers, 5, 15)
        console:drawLog()
    end
end

