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

    self:setVectors(40, 40)
end

function Bat:setVectors(x, y)
    if math.random() < 0.5 then
        x, y = vector.rotate(x, y, math.random() < 0.5 and TAU / 16 or -TAU / 16)
    end

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
    if entity.block then
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
end


function Bat:update(dt)
    getmetatable(Bat).update(self, dt)

    local a,b,c,d = self:getbb()
    for i, entity in ipairs(game.entities) do
        if entity.block and entity.thrown then
            local w,x,y,z = entity:getbb()
            if rect.intersects(a,b,c,d,w,x,y,z) then
                self:kill()
            end
        end
    end
end

