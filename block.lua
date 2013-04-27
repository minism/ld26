require 'math'



Block = PhysEntity:extend()

function Block:init(data)
    self.block = true
    self.color = 1

    getmetatable(Block).init(self, data)
end

function Block:draw()
    getmetatable(Block).draw(self)
    colors['block_' .. self.color]()
    sprite.drawSprite(1, self.x, self.y)
end





BlockHint = Entity:extend()

function BlockHint:init(data)
    self.life = BLOCK_TIMER
    self.flash_speed = 0.25

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
        sprite.drawSprite(9, self.x, self.y)
    end
end