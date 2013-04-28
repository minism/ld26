--
-- Game constants
--

REAL_W = 624
REAL_H = 768
TAU = math.pi * 2
BLOCK_SIZE = 16
WORLD_BLOCKS_X = 11
WORLD_BLOCKS_Y = 14
WORLD_W = BLOCK_SIZE * WORLD_BLOCKS_X
WORLD_H = BLOCK_SIZE * WORLD_BLOCKS_Y
CAMERA_SCALE = 3
SCREEN_W = REAL_W / CAMERA_SCALE
SCREEN_H = REAL_H / CAMERA_SCALE
BLOCK_TIMER = 1
CHAIN_TIME = 0.5
CHAIN_SIZE = 3
GRAVITY = 600
MOVE_SPEED = 60
JUMP_POWER = 225
JUMP_TIME = 10 / 60
THROW_POWER = 175
THROW_ANGLE = TAU / 8
ANIM_SPEED = 1 / 30
LIFT_TIME = ANIM_SPEED * 4
LEFT, TOP, RIGHT, BOTTOM = 0, 1, 2, 3


require 'math'

require 'assets'
require 'sprite'
require 'input'
require 'player'
require 'entity'
require 'block'
require 'input'
require 'phase'

game = leaf.Context()



--
-- Initialization
--
function game:init()
    -- Load all assets
    assets.load()
    sprite.load()
    self.ts = 0

    -- Runtime state flags
    self.flags = {
        debug = true,
        showbb = false,
        blockmap = false,
    }

    self.blockmap = {}
    self.entities = {}
    player:reset()
    player.x = 0
    player.y = WORLD_H - player.h
    game:loadPhase(1)
end


function game:loadPhase(phase)
    game.phase = phases[phase]
    game:initWorld()

    if self.phase.pushrate then
        game:queuePush()
    end

    if self.phase.droprate then
        game:queueDrop()
    end
end


function game:initWorld()
    time:empty()
    tween.stopAll()
    self.pushers = {}
    self.droppers = {}
    self.blockmap = {}
    self.entities = {}
    self:setStaticBlocks()
end



-- Insert static border blocks for world edge collision
function game:setStaticBlocks()
    for i=-1, WORLD_BLOCKS_X do
        local static_block_top = Pusher {
            x=i*BLOCK_SIZE,
            y=-BLOCK_SIZE,
            awake = false,
            sprite = i == -1 and 31 or i == WORLD_BLOCKS_X and 32 or 47,
        }
        local static_block_bot = Pusher {
            x=i*BLOCK_SIZE,
            y=WORLD_H,
            awake = false,
            sprite = i == -1 and 39 or i == WORLD_BLOCKS_X and 40 or 48,
        }
        game:addEntity(static_block_top)
        game:addEntity(static_block_bot)

        if i >= 0 and i < WORLD_BLOCKS_X then
            table.insert(self.droppers, static_block_top)
            table.insert(self.pushers, static_block_bot)
        end
    end
    for i=0, WORLD_BLOCKS_Y-1 do
        local static_block_left = Pusher {
            y=i*BLOCK_SIZE,
            x=-BLOCK_SIZE,
            awake = false,
            sprite = 45,
        }
        local static_block_right = Pusher {
            y=i*BLOCK_SIZE,
            x=WORLD_W,
            awake = false,
            sprite = 46,
        }
        game:addEntity(static_block_left)
        game:addEntity(static_block_right)
    end
end


--
-- Query
--

function game:findBlockUnder(source)
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


-- function game:freeBlockSpace(col, row)
--     if col >= 0 and col < WORLD_BLOCKS_X and row >= 0 and row < WORLD_BLOCKS_Y then
--         local l,r,t,b = cr2pos(col, row)
--         for i, entity in ipairs(self.entities) do
--             if entity.block then
--                 local x,y,x2,y2 = entity:getbb()
--                 if overlaps(l+1,r,x,x2) and overlaps(t,b,y,y2) then
--                     return false
--                 end
--             end
--         end
--         return true
--     end
--     return false
-- end


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

function game:randomColor()
    return math.random(1, #self.phase.colors)
end


function game:addEntity(entity)
    table.insert(self.entities, entity)
end

function game:removeEntity(entity)
    remove_if(self.entities, function(e) return e == entity end)
end

function game:queuePush()
    for i, block in ipairs(self.pushers) do
        block.blink = 1
        tween(BLOCK_TIMER, block, {blink=0}, 'outCubic')
    end
    time:after(BLOCK_TIMER, function() self:pushColumns() end)
    if self.phase.pushrate then
        time:after(math.random(unpack(self.phase.pushrate)), function()
            self:queuePush()
        end)
    end
end

function game:pushColumns()
    last_color = nil
    color_count = 1
    for col=0, WORLD_BLOCKS_X - 1 do

        local color = game:randomColor()
        if color == last_color then
            color_count = color_count + 1
            if color_count >= 3 then
                color_count = 1
                color = (color % #self.phase.colors) + 1
            end
        end
        last_color = color

        local x, y = cr2pos(col, WORLD_BLOCKS_Y - 1)
        local block = Block { x = x, y = y, color=color }
        block.grounded = true
        block.rested = true
        self:addEntity(block)

        local highest_grounded = nil
        for i, entity in ipairs(self.entities) do
            local c, r = entity:getcr()
            if c == col then
                if entity.grounded then
                    if not highest_grounded or entity.y < highest_grounded.y then
                        highest_grounded = entity
                    end

                    if entity ~= block then
                        entity.y = entity.y - BLOCK_SIZE 
                    end
                end
            end
        end

        for i, entity in ipairs(self.entities) do
            if entity.awake and not entity.grounded and entity.solid then
                local a,b,c,d = entity:getbb()
                local w,x,y,z = highest_grounded:getbb()
                if rect.intersects(a,b,c,d,w,x,y,z) then
                    entity.y = highest_grounded.y - entity.h
                end
            end
        end

        if player:getcr() == col then
            if player.grounded then
                player.y = player.y - BLOCK_SIZE
            elseif highest_grounded then
                local a,b,c,d = player:getbb()
                local w,x,y,z = highest_grounded:getbb()
                if rect.intersects(a,b,c,d,w,x,y,z) then
                    player.y = highest_grounded.y - player.h
                end
            end
        end
    end


    -- Update block map
    for c=0,WORLD_BLOCKS_X-1 do
        for r=0,WORLD_BLOCKS_Y-1 do
            self.blockmap[cr2idx(c,r)] = nil
        end
    end
    for i, entity in ipairs(game.entities) do
        if entity.block and entity.rested then
            game:blockRested(entity)
        end
    end
end


function game:queueDrop(data)
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


    if self.phase.droprate then
        time:after(math.random(unpack(self.phase.droprate)), function()
            self:queueDrop()
        end)
    end
end

function game:queueClear(block)
    -- Remove from block map immediately and set chaining active
    block.chaining = true
    game:unsetBlock(block)

    -- Queue animation and delete
    tween(CHAIN_TIME, block, {fade=1}, 'inQuad')
    local glare = BlockGlare({x=block.x, y=block.y})
    game:addEntity(glare)
    time:after(CHAIN_TIME, function()
        glare.alive = false
        block.alive = false
    end)
end



function game:unsetBlock(block)
    game.blockmap[block:getidx()] = nil
end


function game:removeBlock(block)
    game:unsetBlock(block)
    game:removeEntity(block)
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
    self.ts = self.ts + dt
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
    colors.white()

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
    lg.setScissor((REAL_W - WORLD_W * CAMERA_SCALE) / 2, (REAL_H - WORLD_H * CAMERA_SCALE) / 2, WORLD_W * CAMERA_SCALE, WORLD_H * CAMERA_SCALE)
        sprite.drawScrollingBackground(2, game.ts*5, 0)
        sprite.drawScrollingBackground(3, game.ts*15, 0)
        sprite.drawScrollingBackground(3, game.ts*32, 64)
    lg.setScissor()

    -- Draw entities sorted by z index
    for z=0, 3 do
        for i, entity in ipairs(self.entities) do
            if entity.z_index == z then
                entity:draw()
            end
        end
    end

    -- Draw blockmap debug
    colors.white()
    if self.flags.blockmap then
        for i=0, WORLD_BLOCKS_X-1 do
            for j=0, WORLD_BLOCKS_Y-1 do
                local idx = cr2idx(i, j)
                if self.blockmap[idx] then
                    local x, y = cr2pos(i, j)
                    love.graphics.print(self.blockmap[idx].color, x+2, y+2)
                end
            end
        end
    end

    player:draw()
end


function game:drawHUD()    
    colors.console()
    if self.flags.debug then
        lg.print("FPS: " .. love.timer.getFPS(), 5, 5)
        lg.print("#Timers: " .. #time.timers, 5, 15)
        lg.print("#Tweens: " .. tween.count(), 5, 25)
        lg.print("#Entities: " .. #self.entities, 5, 35)
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
    if input.match('blockmap', key) then
        self.flags.blockmap = not self.flags.blockmap
    end
    if input.match('init', key) then
        game:loadPhase(1)
    end
end

