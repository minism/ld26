require 'math'



Block = PhysEntity:extend()

function Block:init(data)
    self.rested = false
    self.thrown = false
    self.block = true
    self.chaining = false
    self.color = game:randomColor()

    getmetatable(Block).init(self, data)

    self.sprite = 3
end

function Block:update(dt)
    getmetatable(Block).update(self, dt)

    if self.grounded and self.velx == 0 and self.vely == 0 and not self.rested then
        -- Block is rested for the first time
        self.rested = true
        self.thrown = false
        game:blockRested(self)
    elseif not self.grounded then
        game:unsetBlock(self)
        self.rested = false
    end
end

function Block:getColor()
    return game.phase.colors[self.color]
end

function Block:collideWith(target, side)
    if target.block and side == TOP and not self._last_grounded then
        game:sound('drop')
    elseif target == player and side == TOP then
        player.headblock = self
    elseif target.enemy and self.thrown then
        target:kill()
    end
end

function Block:collideGeo(direction)
    if direction == TOP and not self._last_grounded then
        game:sound('drop')
    end
end

function Block:getbbFor(entity)
    if entity == player then
        return entity:getbb_block()
    else
        return entity:getbb()
    end
end

function Block:updateVectors(dt)
    getmetatable(Block).updateVectors(self, dt)
end





BlockHint = Entity:extend()

function BlockHint:init(data)
    self.life = BLOCK_TIMER
    self.flash_speed = 0.1

    getmetatable(BlockHint).init(self, data)

    self.ts = self.life
end

function BlockHint:update(dt)
    getmetatable(BlockHint).update(self, dt)
    self.ts = self.ts - dt
    if self.ts < 0 then
        self.alive = false
    end
end

function BlockHint:draw()
    getmetatable(BlockHint).draw(self)

    colors.white()
    if self.ts % self.flash_speed > self.flash_speed / 2 then
        sprite.drawSprite(8, self.x, self.y)
    end
end


BlockGlare = Entity:extend()

function BlockGlare:init(data)
    getmetatable(BlockGlare).init(self, data)
    self.sprite = 9
    self.anim_size = 8
    self.anim_speed = 1 / 16
    self.anim_once = true
end