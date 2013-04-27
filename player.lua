require 'entity'

player = PhysEntity()

player.w = 8
player.h = 16
player.grounded = true
player.vely = 0
player.solid = false


function player:draw()
    getmetatable(player).draw(self)
    sprite.drawSprite(33, self.x, self.y)
end


function player:updateVectors(dt)
    self.vely = self.vely + GRAVITY * dt
    if input.down('left') then
        self.velx = -MOVE_SPEED
    elseif input.down('right') then
        self.velx = MOVE_SPEED
    else
        self.velx = 0
    end
end

