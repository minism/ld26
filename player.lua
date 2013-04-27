require 'entity'

player = Entity()

player.w = 8
player.h = 16
player.grounded = true
player.vely = 0


function player:draw()
    getmetatable(player).draw(self)


    sprite.drawSprite(33, self.x, self.y)
end

function player:update(dt)
    self.last_x, self.last_y = self.x, self.y

    -- Process input
    if input.down('left') then
        self.x = self.x + -MOVE_SPEED * dt
    elseif input.down('right') then
        self.x = self.x + MOVE_SPEED * dt
    end

    if self.grounded and input.down('jump') then
        self.grounded = false
        self.vely = self.vely - JUMP_POWER
    end

    -- Gravity
    self.vely = self.vely + GRAVITY * dt
    self.y = self.y + self.vely * dt


    -- Check if passed through floor
    if self.last_y + self.h <= WORLD_H and self.y + self.h > WORLD_H then
        self.y = WORLD_H - self.h
        self.grounded = true
        self.vely = 0
    end


    -- Check level boundary collision
    if self.x < 0 then
        self.x = 0
    elseif self.x + self.w > WORLD_W then
        self.x = WORLD_W - self.w
    end
end

