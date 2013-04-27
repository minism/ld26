require 'entity'

player = Entity()

player.w = 8
player.h = 12


function player:draw()
    getmetatable(player).draw(self)


    sprite.drawSprite(33, self.x, self.y)
end

