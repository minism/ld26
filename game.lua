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
BLOCK_TIMER = 1
CHAIN_TIME = 0.5
CHAIN_SIZE = 3
GRAVITY = 225
MOVE_SPEED = 60
JUMP_POWER = 120
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
    self.blockmap = {}
    self.entities = {}
    self:setStaticBlocks()

    -- Position player
    player:reset()
    player.x = 0
    player.y = WORLD_H - player.h

    -- DEBUG
    -- self:queueBlock({pos=1})
    -- time:after(0.1, function() self:queueBlock({pos=2}) end)
    -- time:after(0.2, function() self:queueBlock({pos=3}) end)
    -- self:queueBlock()
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
-- Query
--

function game:findBlocKUnder(source)
    local sl,st,sr,sb = source:getbb()
    for i, entity in ipairs(self.entities) do
        if entity.block and entity.grounded and not entity.chaining then
            local l,t,r,b = entity:getbb()
            if overlaps(sl, sr, l, r) and sb == t then
                return entity
            end
        end
    end
end


function game:getHighestBlock(column)
    local x = column * BLOCK_SIZE + 1
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
-- Control
--
function game:addEntity(entity)
    table.insert(self.entities, entity)
end

function game:removeEntity(entity)
    remove_if(self.entities, function(e) return e == entity end)
end


function game:queueBlock(data)
    local data = data or {}
    local pos = data.pos or math.random(0, WORLD_BLOCKS_X - 1)
    local x = BLOCK_SIZE * pos

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

function game:queueClear(block)
    -- Remove from block map immediately and set chaining active
    block.chaining = true
    game.blockmap[block:getidx()] = nil

    -- Queue animation and delete
    tween(CHAIN_TIME, block, {fade=1}, 'inQuad')
    local glare = BlockGlare({x=block.x, y=block.y})
    game:addEntity(glare)
    time:after(CHAIN_TIME, function()
        glare.alive = false
        block.alive = false
    end)
end


function game:blockRested(block)
    -- Insert into blockmap
    local col, row = block:getcr()
    local idx = block:getidx()
    self.blockmap[idx] = block

    -- Attempt to find a chain
    function query(qcol, qrow)
        local qblock = self.blockmap[cr2idx(qcol, qrow)]
        return qblock and qblock.color == block.color
    end

    local matches = 0 
    for qx = col-2,col+2 do
        if qx >= 0 and qx < WORLD_BLOCKS_X then
            if query(qx, row) then
                matches = matches + 1
                if matches >= CHAIN_SIZE then
                    return game:makeChain(block)
                end
            else
                matches = 0
            end
        end
    end

    matches = 0
    for qy = row-2,row+2 do
        if qy >= 0 and qy < WORLD_BLOCKS_Y then
            if query(col, qy) then
                matches = matches + 1
                if matches >= CHAIN_SIZE then
                    return game:makeChain(block)
                end
            else
                matches = 0
            end
        end
    end
end


function game:makeChain(block)
    -- Build connected graph
    local chainset = {}
    function chain(qcol, qrow)
        local idx = cr2idx(qcol, qrow)
        local qblock = self.blockmap[cr2idx(qcol, qrow)]
        if qblock and qblock.color == block.color then
            if not chainset[qblock] then
                chainset[qblock] = true
                if qcol > 0 then chain(qcol-1, qrow) end
                if qcol < WORLD_BLOCKS_X - 1 then chain(qcol+1, qrow) end
                if qrow > 0 then chain(qcol, qrow-1) end
                if qrow < WORLD_BLOCKS_Y - 1 then chain(qcol, qrow+1) end
            end
        end
    end
    chain(block:getcr())

    for block, v in pairs(chainset) do
        game:queueClear(block)
    end
end





-- 
-- Update
--


function game:update(dt)
    input.update(dt)
    time:update(dt)
    if dt > 0 then
        tween.update(dt)
    end

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
        lg.print("#Tweens: " .. tween.count(), 5, 25)
        console:drawLog()
    end
end



--
-- Input
--



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

