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
    self:setAnimation(IDLE)
end

function player:setAnimation(state)
    self.sprite = 18
    self.anim_size = 6
end


function player:draw()
    getmetatable(player).draw(self)
    colors.white()
    if self.holding then
        sprite.drawSprite(self.holding.sprite, self.x, self.y)
        sprite.drawSprite(17, self.x + 2, self.y + BLOCK_SIZE)
    else
        sprite.drawSprite(self:spriteFrame(), self.x, self.y)
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