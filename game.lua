--
-- Game constants
--

REAL_W = 624
REAL_H = 768
TAU = math.pi * 2
BLOCK_SIZE = 16
WORLD_BLOCKS_X = 9
WORLD_BLOCKS_Y = 12
WORLD_W = BLOCK_SIZE * WORLD_BLOCKS_X
WORLD_H = BLOCK_SIZE * WORLD_BLOCKS_Y
CAMERA_SCALE = 3
HUD_OFFSET = 10
HUD_DIMENSIONS = {0, -2, 8, -2, true}
SCREEN_W = REAL_W / CAMERA_SCALE
SCREEN_H = REAL_H / CAMERA_SCALE
BLOCK_TIMER = 0.8
LIVES = 1
BASE_CLEARS = 25
CHAIN_TIME = 0.5
CHAIN_SIZE = 3
GRAVITY = 575
MOVE_SPEED = 60
JUMP_POWER = 225
JUMP_TIME = 10 / 60
BATLIMIT = 5
THROW_POWER = 175
THROW_ANGLE = TAU / 8
ANIM_SPEED = 1 / 30
SOUND_DEBOUNCE = 1 / 20
LIFT_TIME = ANIM_SPEED * 4
LEFT, TOP, RIGHT, BOTTOM = 0, 1, 2, 3


require 'math'

require 'input'
require 'player'
require 'entity'
require 'block'
require 'input'
require 'phase'
require 'enemy'
require 'menu'

game = leaf.Context()



--
-- Initialization
--
function game:init()
    -- Load all assets
    self.ts = 0

    -- Runtime state flags
    self.flags = {
        debug = false,
        showbb = false,
        blockmap = false,
    }

    self.push_timer = -10
    self.soundtimers = {}
    self.blockmap = {}
    self.entities = {}
    player:reset()
    player.x = 0
    player.y = WORLD_H - player.h
    game:initWorld()
    game:loadPhase(1)


    game:music 'mus1'
end


function game:loadPhase(phasen)
    self.phasen = phasen
    if phases[self.phasen] then
        self.phase = phases[phasen]
    end
    self.clears = 0

    if self.phase.pushrate then
        time:after(self.phase.pushrate[1], function() self:queuePush() end)
    end

    if self.phase.droprate then
        time:after(self.phase.droprate[1], function() self:queueDrop() end)
    end

    if self.phase.batrate then
        time:after(self.phase.batrate[1], function() self:queueBat() end)
    end
end

function game:nextPhase()
    game:sound 'phase'
    self:loadPhase(self.phasen + 1)
end


function game:initWorld()
    time:empty()
    tween.stopAll()
    self.blockmap = {}
    self.entities = {}
    self:setStaticBlocks()
    self.total_clears = 0
    self.lives = LIVES
end



-- Insert static border blocks for world edge collision
function game:setStaticBlocks()
    local static_block_top = Pusher {
        x=-BLOCK_SIZE,
        y=-BLOCK_SIZE,
        h=BLOCK_SIZE-1,
        w=WORLD_W + BLOCK_SIZE * 2,
        awake = false,
    }
    local static_block_bot = Pusher {
        x=-BLOCK_SIZE,
        y=WORLD_H,
        w=WORLD_W + BLOCK_SIZE * 2,
        awake = false,
    }
    game:addEntity(static_block_top)
    game:addEntity(static_block_bot)
    local static_block_left = Pusher {
        y=0,
        x=-BLOCK_SIZE,
        w=BLOCK_SIZE-1,
        h=WORLD_H,
        awake = false,
    }
    local static_block_right = Pusher {
        y=0,
        x=WORLD_W,
        h=WORLD_H,
        awake = false,
    }
    game:addEntity(static_block_left)
    game:addEntity(static_block_right)
end


--
-- Query
--

function game:findBlockDir(source, direction)
    local sl,st,sr,sb = source:getbb()
    for i, entity in ipairs(self.entities) do
        if entity.block and entity.grounded and not entity.chaining then
            local l,t,r,b = entity:getbb()

            if direction == BOTTOM then
                if overlaps(sl, sr, l, r) and sb == t then
                    return entity
                end
            elseif direction == LEFT then
                if overlaps(st, sb, t, b) and sl == r then
                    return entity
                end
            elseif direction == RIGHT then
                if overlaps(st, sb, t, b) and sr == l then
                    return entity
                end
            end
        end
    end
end

function game:randomColor()
    return math.random(1, self.phase.color_limit or #self.phase.colors)
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

function game:respawn()
    self.lives = self.lives - 1
    if self.lives <= 0 then
        menu:lose()
    end


    local center = math.floor(WORLD_BLOCKS_X / 2)
    -- for i=0, WORLD_BLOCKS_X do
    player.x, player.y = cr2pos(center, 0)
end



function game:checkClears()
    if self.clears > BASE_CLEARS + (self.phasen - 1) * 5 then
        self:nextPhase()
    end
end

function game:addEntity(entity)
    table.insert(self.entities, entity)
end

function game:removeEntity(entity)
    remove_if(self.entities, function(e) return e == entity end)
end

function game:queueBat()
    local ct = 0
    for i, entity in ipairs(self.entities) do
        if entity.enemy then 
            ct = ct + 1
        end
    end
    if ct < BATLIMIT then
        self:addEntity(Bat())
    end

    local queue_phase = self.phasen
    if self.phase.batrate then
        time:after(randrange(self.phase.batrate), function()
            if self.phasen == queue_phase then
                self:queueBat()
            end
        end)
    end
end

function game:queuePush()
    self.push_timer = 0
    local faller = PhysEntity { x = -BLOCK_SIZE, y = 0, sprite = 55}
    game:sound 'fall'
    self:addEntity(faller)
    time:after(BLOCK_TIMER, function() 
        game:sound 'push'
        self:pushColumns() 
        faller.alive = false
    end)

    local queue_phase = self.phasen
    if self.phase.pushrate then
        time:after(randrange(self.phase.pushrate), function()
            if self.phasen == queue_phase then
                self:queuePush()
            end
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
                color = (color % (self.phase.color_limit or #self.phase.colors)) + 1
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

    local block = nil
    if self.phase.bombchance and math.random() < self.phase.bombchance then
        block = Bomb {
            x=x, y=0
        }
    else
        block = Block {
            x = x,
            y = 0,
        }
    end

    -- Queue block
    time:after(BLOCK_TIMER, function() 
        self:addEntity(block)
    end)


    local queue_phase = self.phasen
    if self.phase.droprate then
        time:after(randrange(self.phase.droprate), function()
            if self.phasen == queue_phase then
                self:queueDrop()
            end
        end)
    end
end

function game:queueClear(block)
    -- Remove from block map immediately and set chaining active
    block.chaining = true
    game:unsetBlock(block)

    -- Queue animation and delete
    block.sprite = 2
    local glare = BlockGlare({x=block.x, y=block.y})
    game:addEntity(glare)
    time:after(CHAIN_TIME, function()
        self.total_clears = self.total_clears + 1
        self.clears = self.clears + 1
        self:checkClears()
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
                    game:sound 'match'
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
                    game:sound 'match'
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

        if block.bomb then
            for c=0,WORLD_BLOCKS_X-1 do
                for r=0,WORLD_BLOCKS_Y-1 do
                    local b = self.blockmap[cr2idx(c,r)]
                    if b and b.color == block.color then
                        game:queueClear(b)
                    end
                end
            end
        end
    end

    time:after(CHAIN_TIME, function() self:sound 'chain' end)
end





-- 
-- Update
--


function game:update(dt)
    self.ts = self.ts + dt
    input.update(dt)
    time:update(dt)

    self.push_timer = self.push_timer + dt
    for k, v in pairs(self.soundtimers) do
        self.soundtimers[k] = v - dt
    end

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
        lg.setColor(self.phase.colors.bg or colors.white)
        sprite.drawBackground(1, 0, 0)
        colors.white()

        -- Center world drawing
        lg.translate((SCREEN_W - WORLD_W) / 2, (SCREEN_H - WORLD_H) / 2 + HUD_OFFSET)
        self:drawWorld()
    lg.pop()

    self:drawHUD()
end


function game:drawFrame(x1, y1, x2, y2, bg)
    local bs = BLOCK_SIZE

    if bg then
        for i=x1,x2 do
            for j=y1,y2 do
                sprite.drawSprite(7, i*bs, j*bs)
            end
        end
    end

    for i=x1,x2 do
        sprite.drawSprite(47, i * bs, y1 * bs - bs)
        sprite.drawSprite(48, i * bs, y2 * bs + bs)
    end
    for j=y1,y2 do
        sprite.drawSprite(45, x1 * bs - bs, j * bs)
        sprite.drawSprite(46, x2 * bs + bs, j * bs)
    end
    sprite.drawSprite(31, x1 * bs - bs, y1 * bs - bs)
    sprite.drawSprite(32, x2 * bs + bs, y1 * bs - bs)
    sprite.drawSprite(39, x1 * bs - bs, y2 * bs + bs)
    sprite.drawSprite(40, x2 * bs + bs, y2 * bs + bs)
end


function game:drawWorld()
    -- Draw level background
    lg.setScissor((REAL_W - WORLD_W * CAMERA_SCALE) / 2, (REAL_H - WORLD_H * CAMERA_SCALE) / 2 + HUD_OFFSET * CAMERA_SCALE, WORLD_W * CAMERA_SCALE, WORLD_H * CAMERA_SCALE)
        sprite.drawScrollingBackground(2, game.ts*self.phasen, 0)
        sprite.drawScrollingBackground(3, game.ts*self.phasen*3, 0)
        sprite.drawScrollingBackground(3, game.ts*self.phasen*5, 64)
    lg.setScissor()

    -- Draw frame
    game:drawFrame(0, 0, WORLD_BLOCKS_X-1, WORLD_BLOCKS_Y-1)

    -- Draw entities
    for i, entity in ipairs(self.entities) do
        entity:draw()
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

    -- Draw push decals
    local pushsprite = self.push_timer > BLOCK_TIMER and self.push_timer < BLOCK_TIMER * 2 and 54 or 53
    sprite.drawSprite(pushsprite, -BLOCK_SIZE, WORLD_H)

    -- Draw scoreboard
    game:drawFrame(unpack(HUD_DIMENSIONS))
    player:draw()
end


function game:drawHUD()
    local hx, hy = 110, 47
    colors.score1()
    lg.setFont(assets.font)
    lg.print("PHASE ", hx, hy)
    lg.print("LIVES ", hx + 130, hy)
    lg.print("BLOCKS ", hx + 260, hy)
    colors.score2()
    lg.print(self.phasen, hx + 75, hy)
    lg.print(self.lives, hx + 210, hy)
    lg.print(self.total_clears, hx + 350, hy)

    colors.console()
    if self.flags.debug then
        lg.setFont(assets.font_debug)
        lg.print("FPS: " .. love.timer.getFPS(), 5, 5)
        lg.print("#Timers: " .. #time.timers, 5, 15)
        lg.print("#Tweens: " .. tween.count(), 5, 25)
        lg.print("#Entities: " .. #self.entities, 5, 35)
        console:drawLog()
    end
end


function game:sound(sound)
    if not self.soundtimers[sound] or self.soundtimers[sound] < 0 then
        self.soundtimers[sound] = SOUND_DEBOUNCE
        assets.sfx[sound]:play()
    end
end

function game:music(music)
    assets.mus[music]:play()
    assets.mus[music]:setLooping(true)
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
        -- game:loadPhase(1)
    end
end

