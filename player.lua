require 'entity'

player = PhysEntity()

player.w = 8
player.h = 16
player.grounded = true
player.vely = 0
player.solid = false
player.z_index = 1
player.lift_timer = 0
player.jump_timer = 0
player.jump_fuel = 1.0
player.invincible = 0

local IDLE, RUN, CARRY_IDLE, CARRY_RUN, LIFTING = 0, 1, 2, 3, 4


function player:reset()
    self.holding = nil
    self.headblock = nil
    self:setState(IDLE)
end

function player:setState(state)
    if state ~= self.state then
        self:resetAnimation()
    end

    self.state = state
    if state == IDLE then
        self.sprite = 17
        self.anim_size = 1
    elseif state == CARRY_IDLE then
        self.sprite = 17 + 4
        self.anim_size = 1
    elseif state == RUN then
        self.sprite = 25
        self.anim_size = 6
    elseif state == CARRY_RUN then
        self.sprite = 33
        self.anim_size = 6
    elseif state == LIFTING then
        self.sprite = 41
        self.anim_size = 5
    end
end


function player:getbb_block()
    local l, t, r, b = self:getbb()
    if self.holding then
        t = t - self.holding.h
    end
    return l, t, r, b
end


function player:draw()
    if self.invincible > 0 and game.ts % 0.1 < 0.05 then
        -- nop
    else
        lg.setColor(self:getColor())
        if type(self.sprite) == 'number' then
            sprite.drawSprite(self:spriteFrame(), self:getDrawParams())
        end

        if self.holding then
            local x = self.x - (self.holding.w - self.w) / 2
            local y = self.y - self.h
            if self.state == LIFTING then
                y = self.y - (self.anim_frame + 1) / 4 * self.h
            end
            lg.setColor(self.holding:getColor())
            sprite.drawSprite(self.holding:spriteFrame(), x, y)
        end

        if game.flags.showbb then
            colors.debug()
            local l,t,r,b = self:getbb_block()
            love.graphics.rectangle('line', l, t, r-l, b-t)
        end
    end
end

function player:die()
    game:sound 'die'
    self:reset()
    game:respawn()
end

function player:updateVectors(dt)
    if self.state ~= LIFTING then
        if input.downFrame('jump') and self.grounded then
            self.jump_fuel = 1.0
            self.jump_timer = JUMP_TIME
            self.grounded = false
        end

        if input.down('jump') and self.jump_fuel > 0 then
            local last_fuel = self.jump_fuel
            self.jump_timer = self.jump_timer - dt
            local alpha = self.jump_timer / JUMP_TIME
            local usage = (alpha * alpha * alpha) / 2
            self.jump_fuel = math.max(self.jump_fuel - usage, 0)
            local fuel_delta = last_fuel - self.jump_fuel
            self.vely = self.vely - JUMP_POWER * fuel_delta
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
end

function player:step(dt)
    getmetatable(player).step(self, dt)

    if self.headblock then
        -- Check if we're still underneath it
        if overlaps(self.x, self.x+self.w, self.headblock.x, self.headblock.x+self.headblock.w) then
            self.y = self.headblock.y + self.headblock.h
            if self.holding then
                self.y = self.y + self.holding.h
            end
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
    self.invincible = self.invincible - dt

    if self.state == LIFTING then
        if self.anim_frame == 4 then
        -- if self.lift_timer > LIFT_TIME then
            self:setState(CARRY_IDLE)
        end
    else
        if self.velx < 0 then
            self.right = false
        elseif self.velx > 0 then
            self.right = true
        end

        if math.abs(self.velx) > 0 then
            self:setState(self.holding and CARRY_RUN or RUN)
        else
            self:setState(self.holding and CARRY_IDLE or IDLE)
        end
    end

    if input.downFrame('grab') and self.state ~= LIFTING then
        if self.grounded and not self.holding then
            local block = nil
            local under = false
            if input.down('left') then
                block = game:findBlockDir(self, LEFT)
            elseif input.down('right') then
                block = game:findBlockDir(self, RIGHT)
            end

            if not block then
                block = game:findBlockDir(self, BOTTOM)
                under = true
            end
            if block then
                self:liftBlock(block, under)
            end

        elseif self.holding then
            self:setBlock()
        end
    end

    if input.downFrame('throw') and self.state ~= LIFTING and self.holding then
        self:throwBlock()
    end

    for i, entity in ipairs(game.entities) do
        if entity.enemy then
            local a,b,c,d = self:getbb()
            local w,x,y,z = entity:getbb()
            if rect.intersects(a,b,c,d,w,x,y,z) then
                if self.invincible <= 0 then
                    self:die()
                end
            end
        end
    end

    if self.y + self.h <= 0 then
        self:die()
    end
end


function player:liftBlock(block, under)
    game:sound 'grab'

    if under then
        self.y = self.y + block.h
    end

    block.rested = false
    self.holding = block
    self.lift_timer = 0
    self.velx = 0
    self:setState(LIFTING)
    game:removeBlock(block)
end

function player:setBlock()
    game:sound 'ungrab'
    local block = self.holding
    self.holding = nil
    local col, row = self:getcentercr()
    col = constrain(col, 0, WORLD_BLOCKS_X-1)
    row = constrain(row, 0, WORLD_BLOCKS_Y-1)
    local bx, by = cr2pos(col, row)
    block.x = bx
    block.y = self.y
    self.y = self.y - self.h
    game:addEntity(block)
end

function player:throwBlock()
    game:sound 'throw'
    local block = self.holding
    self.holding = nil
    block.x = self.x
    if self.right then
        block.x = self.x - block.w + self.w
    end
    block.y = self.y - block.h
    block.thrown = true
    block.throw_timer = 0.1

    -- Throw at 45 degree angle
    local vec = vector(0, -1)
    local rotation = self.right and THROW_ANGLE or -THROW_ANGLE

    -- Arc upwards a bit if jumping
    if input.down('jump') then
        rotation = rotation * 0.75
    end

    local vx, vy = vector.rotate(vec, rotation)
    block.velx = vx * THROW_POWER
    block.vely = vy * THROW_POWER

    game:addEntity(block)

    -- Check for X snap
    -- for i, entity in ipairs(game.entities) do
    --     local l,r,t,b = entity:getbb()
    --     if overlaps(block.y, block.y+block.h, t, b) then
    --         if overlaps(block.x, block.x+block.w, l, r) then
    --             block.x = r
    --         end
    --     end
    -- end

end