require 'math'



Block = PhysEntity:extend()

function Block:init(data)
    self.rested = false
    self.block = true
    self.chaining = false
    self.color = math.random(1, 3)
    self.fade = 0

    getmetatable(Block).init(self, data)

    self.sprite = 2
end

function Block:update(dt)
    getmetatable(Block).update(self, dt)

    if self.grounded and self.velx == 0 and self.vely == 0 and not self.rested then
        -- Block is rested for the first time
        self.rested = true
        game:blockRested(self)
    elseif not self.grounded then
        self.rested = false
    end
end

function Block:getColor()
    local clr = colors['block_' .. self.color]
    return color.desaturate(clr, self.fade * 255)
end

function Block:collideWith(target, side)
    if target == player and side == TOP then
        player.headblock = self
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
    self.anim_speed = 1 / 24
    self.anim_once = true
end