require 'math'



Block = PhysEntity:extend()

function Block:init(data)
    self.color = 1

    getmetatable(Block).init(self, data)
end

function Block:draw()
    getmetatable(Block).draw(self)
    colors['block_' .. self.color]()
    sprite.drawSprite(1, self.x, self.y)
end

function Block:update(dt)
    getmetatable(Block).update(self, dt)

    -- Check if we passed through a block or the world floor
    if self.awake then
        local highest_block = game:getHighestBlock(self:getColumn())
        if highest_block then
            if self.last_y + self.h < highest_block.y and self.y + self.h >= highest_block.y then
                game:trigger('block_land', self, highest_block)
            end
        else
            local floor_y = WORLD_H
            if self.last_y + self.h < floor_y and self.y + self.h >= floor_y then
                game:trigger('block_land', self)
            end
        end
    end
end

function Block:getColumn()
    return math.floor(self.x / BLOCK_SIZE) + 1
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