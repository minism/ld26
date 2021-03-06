DataObject = Object:extend()
DataObject.defaults = {}

function DataObject:init(data)
    _.extend(self, data or {})
end





Entity = DataObject:extend()

function Entity:init(data)
    self.x = 0
    self.y = 0
    self.h = BLOCK_SIZE
    self.w = BLOCK_SIZE
    self.right = true
    self.alive = true
    self.z_index = 0

    -- Animation data
    self.anim_size = 1
    self.anim_timer = 0
    self.anim_frame = 0
    self.anim_speed = ANIM_SPEED

    getmetatable(Entity).init(self, data)
end

function Entity:resetAnimation()
    self.anim_frame = 0
    self.anim_timer = 0
end

function Entity:update(dt)
    self.anim_timer = self.anim_timer + dt
    if self.anim_timer > self.anim_speed then
        self.anim_timer = self.anim_timer - self.anim_speed
        self.anim_frame = self.anim_frame + 1
        if self.anim_frame >= self.anim_size then
            self.anim_frame = 0
            if self.anim_once then
                self.anim_frame = self.anim_size - 1
            end
        end
    end
end

function Entity:getDrawParams()
    local x = self.right and self.x or self.x + self.w
    local sx = self.right and 1 or -1
    local y = self.y
    local r = 0
    local sy = 1
    return x, y, r, sx, sy
end

function Entity:setSprite(sprite, anim_size)
    self.sprite = sprite
    self.anim_size = anim_size or 1
end

function Entity:getColor()
    return colors.white
end

function Entity:draw()
    lg.setColor(self:getColor())

    if type(self.sprite) == 'number' then
        sprite.drawSprite(self:spriteFrame(), self:getDrawParams())
    end
end

function Entity:spriteFrame()
    return self.sprite + self.anim_frame
end

function Entity:getcr()
    return pos2cr(self.x, self.y)
end

function Entity:getcentercr()
    return pos2cr(self.x + self.w / 2, self.y)
end

function Entity:getidx()
    return cr2idx(self:getcr())
end



PhysEntity = Entity:extend()

function PhysEntity:init(data)
    self.collision = true
    self.solid = true
    self.awake = true
    self.last_x = 0
    self.last_y = 0
    self.velx = 0
    self.vely = 0
    self.grounded = false

    getmetatable(PhysEntity).init(self, data)
end

function PhysEntity:getbb()
    return self.x, self.y, self.x + self.w, self.y + self.h
end

function PhysEntity:draw()
    getmetatable(PhysEntity).draw(self)

    if game.flags.showbb then
        colors.debug()
        local l,t,r,b = self:getbb()
        love.graphics.rectangle('line', l, t, r-l, b-t)
    end
end

function PhysEntity:update(dt)
    getmetatable(PhysEntity).update(self, dt)

    if self.awake then
        self:step(dt)
    end
end


-- Update velocity/accel vectors for this frame
function PhysEntity:updateVectors(dt)
    self.vely = self.vely + GRAVITY * dt
end


-- Move according to velocity vectors, and check for collision
local thresh = BLOCK_SIZE * 3
local mid = BLOCK_SIZE / 2
function PhysEntity:step(dt)
    self:updateVectors(dt)
    local nx = self.x + self.velx * dt
    local ny = self.y + self.vely * dt
    self._last_grounded = self.grounded
    self.grounded = false

    -- Check entity collision
    for i, entity in ipairs(game.entities) do
        if entity ~= self and entity.collision then
            if math.abs(self.x + mid - entity.x + mid) < thresh and
               math.abs(self.y + mid - entity.y + mid) < thresh then
                nx, ny = self:projectCollision(nx, ny, entity)
            end
        end
    end

    -- Check geometry collision
    if self.x >= 0 and nx < 0 then
        nx = 0
        self.velx = 0
        self:collideGeo(LEFT)
    elseif self.x + self.w <= WORLD_W and nx + self.w > WORLD_W then
        nx = WORLD_W - self.w
        self.velx = 0
        self:collideGeo(RIGHT)
    end
    if self.y >= 0 and ny < 0 then
        ny = 0
        self.vely = 0
        self:collideGeo(TOP)
    elseif self.y + self.h <= WORLD_H and ny + self.h > WORLD_H then
        self.grounded = true
        ny = WORLD_H - self.h
        self.vely = 0
        self:collideGeo(BOTTOM)
    end

    -- Check player collision
    nx, ny = self:projectCollision(nx, ny, player)

    -- Set new position after collision
    self.x = nx
    self.y = ny
end

function PhysEntity:projectCollision(nx, ny, entity)
    local l, t, r, b = self:getbbFor(entity)
    local ncollide = true

    -- Check x axis collisions
    if overlaps(self.y, self.y + self.h, t, b) then
        if self.x + self.w <= l and nx + self.w > l then
            if entity.solid then
                nx = l - self.w
                self.velx = 0
            end
            self:collideWith(entity, LEFT)
            ncollide = false
        elseif self.x >= r and nx < r then
            if entity.solid then
                nx = r
                self.velx = 0
            end
            self:collideWith(entity, RIGHT)
            ncollide = false
        end
    end

    -- Check y axis collisions
    if overlaps(self.x, self.x + self.w, l, r) then
        if self.y + self.h <= t and ny + self.h > t then
            if entity.solid then
                ny = t - self.h
                self.vely = 0
                self.grounded = true
            end
            self:collideWith(entity, TOP)
            ncollide = false
        elseif self.y >= b and ny < b then
            if entity.block and self.block and self.throw_timer > 0 then
                --nop
            else
                if entity.solid then
                    ny = b
                    self.vely = 0
                end
                self:collideWith(entity, BOTTOM)
                ncollide = false
            end
        end
    end

    -- Check corner collisions
    -- if ncollide then
    --     if overlaps(ny, ny + self.h, t, b) and overlaps(nx, nx + self.w, l, r) then
    --         if self.y < t then
    --             if entity.solid then
    --                 ny = t - self.h
    --                 self.vely = 0
    --                 self.grounded = true
    --             end
    --             self:collideWith(entity, TOP)
    --         else
    --             if entity.solid then
    --                 ny = b
    --                 self.vely = 0
    --             end
    --             self:collideWith(entity, RIGHT)
    --         end
    --     end
    -- end
    return nx, ny
end

function PhysEntity:getbbFor(entity)
    return entity:getbb()
end

function PhysEntity:collideWith(target, side)
end

function PhysEntity:collideGeo()
end



Pusher = PhysEntity:extend()
