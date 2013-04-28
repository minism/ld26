require 'entity'

player = PhysEntity()

player.w = 8
player.h = 16
player.grounded = true
player.vely = 0
player.solid = false
player.z_index = 1

function player:reset()
    self.headblock = nil
end


function player:draw()
    getmetatable(player).draw(self)
    colors.white()
    sprite.drawSprite(33, self.x, self.y)
end

function player:die()
    console:write("Player died")
    self:reset()
    self.x = 0
    self.y = 0
end

function player:updateVectors(dt)
    if input.down('jump') and self.grounded then
        self.grounded = false
        self.vely = -JUMP_POWER
    end

    self.vely = self.vely + GRAVITY * dt


    if input.down('left') then
        self.velx = -MOVE_SPEED
    elseif input.down('right') then
        self.velx = MOVE_SPEED
    else
        self.velx = 0
    end
end

function player:step(dt)
    getmetatable(player).step(self, dt)

    if self.headblock then
        -- Check if we're still underneath it
        if overlaps(self.x, self.x+self.w, self.headblock.x, self.headblock.x+self.headblock.w) then
            self.y = self.headblock.y + self.headblock.h
            self.vely = 0
            
            -- Check if we intersect with any blocks below
            for i, entity in ipairs(game.entities) do
                if entity.solid then
                    local l, t, r, b = entity:getbb()
                    if overlaps(self.x, self.x + self.w, l, r) then
                        if self.y < entity.y and self.y + self.h > entity.y then
                            self:die()
                        end
                    end
                end
            end
        else
            self.headblock = nil
        end
    end
end
