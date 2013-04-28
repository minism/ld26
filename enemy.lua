Enemy = PhysEntity:extend()

function Enemy:init(data)
    getmetatable(Enemy).init(self, data)

    self.enemy = true
    self.solid = false
end

function Enemy:kill()
    self.alive = false
    game:sound('kill')
end



Bat = Enemy:extend()



function Bat:init(data)
    getmetatable(Bat).init(self, data)

    self.sprite = 57
    self.anim_size = 4
    self.anim_speed = 1 / 16
    self.w = 11
    self.h = 5

    self:setVectors(25, 25)
end

function Bat:setVectors(x, y)
    self.velx = x
    self.vely = y
    self._lastvx = x
    self._lastvy = y
end

function Bat:updateVectors(dt)
    self._lastvx = math.abs(self.velx) > 0 and self.velx or self._lastvx
    self._lastvy = math.abs(self.vely) > 0 and self.vely or self._lastvy
end

function Bat:collideWith(entity, direction)
    if entity == player then
        player:die()
    elseif entity.block then
        if entity.thrown then
            self:kill()
        end
        if direction == LEFT or direction == RIGHT then
            self.velx = -self._lastvx
        else
            self.vely = -self._lastvy
        end
    end
end

function Bat:collideGeo(direction)
    if direction == LEFT or direction == RIGHT then
        self.velx = -self._lastvx
    else
        self.vely = -self._lastvy
    end
    console:write(self.velx, self.vely)
end

