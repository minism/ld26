require 'entity'

player = PhysEntity()

player.w = 8
player.h = 16
player.grounded = true
player.vely = 0
player.solid = false
player.z_index = 1

local IDLE, RUNNING = 0, 1


function player:reset()
    self.headblock = nil
    self:setState(IDLE)
end

function player:setState(state)
    if state == IDLE then
        self.sprite = 17
        self.anim_size = 4
    elseif state == RUNNING then
        self.sprite = 25
        self.anim_size = 6
    end
end


function player:draw()
    lg.setColor(self:getColor())
    if type(self.sprite) == 'number' then
        sprite.drawSprite(self:spriteFrame(), self:getDrawParams())
    end
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

function player:update(dt)
    getmetatable(player).update(self, dt)

    if self.velx < 0 then
        self.right = false
    elseif self.velx > 0 then
        self.right = true
    end

    if math.abs(self.velx) > 0 then
        self:setState(RUNNING)
    else
        self:setState(IDLE)
    end

    if input.downFrame('grab') then
        if self.grounded then
            local block = game:findBlocKUnder(self)
            if block then
                self:grabBlock(block)
            end
        end
    end
end

function player:grabBlock(block)
    self.x = block.x + (block.w - self.w) / 2
    self.y = self.y - block.h
    self.h = self.h + block.h
    self.holding = block
    game:removeEntity(block)
end