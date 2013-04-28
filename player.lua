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
player.jump_fuel = JUMP_FUEL

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
        self.anim_size = 4
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

function player:die()
    console:write("Player died")
    self:reset()
    self.x = 0
    self.y = 0
end

function player:updateVectors(dt)
    -- love.timer.sleep(0.015)
    if self.state ~= LIFTING then
        if input.downFrame('jump') and self.grounded then
            self.jump_fuel = 1.0
            self.jump_timer = JUMP_TIME
            self.grounded = false
        end

        if input.down('jump') and self.jump_fuel > 0 then
            -- local last_fuel = self.jump_fuel
            -- self.jump_timer = self.jump_timer - dt
            -- self.jump_fuel = math.max(self.jump_fuel - self.jump_timer, 0)
            -- console:write(self.jump_fuel)
            -- local fuel_delta = last_fuel - self.jump_fuel
            -- self.vely = self.vely - JUMP_POWER  * fuel_delta
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

    if self.state == LIFTING then
        self.lift_timer = self.lift_timer + dt
        if self.lift_timer > LIFT_TIME then
            self.state = CARRY_IDLE
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
            local block = game:findBlockUnder(self)
            if block then
                self:liftBlock(block)
            end
        elseif self.holding then
            self:setBlock()
        end
    end

    if input.downFrame('throw') and self.state ~= LIFTING and self.holding then
        self:throwBlock()
    end
end

function player:liftBlock(block)
    -- self.x = block.x + (block.w - self.w) / 2
    self.y = self.y + block.h
    block.rested = false
    self.holding = block
    self.lift_timer = 0
    self.velx = 0
    self:setState(LIFTING)
    game:removeEntity(block)
end

function player:setBlock()
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
    local block = self.holding
    self.holding = nil
    block.x = self.x - (block.w - self.w) / 2
    block.y = self.y - block.h

    -- Throw at 45 degree angle
    local vec = vector(0, -1)
    local rotation = self.right and TAU / 8 or -TAU / 8
    local vx, vy = vector.rotate(vec, rotation)
    block.velx = vx * THROW_POWER
    block.vely = vy * THROW_POWER

    game:addEntity(block)
end