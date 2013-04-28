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
    self.alive = true
    self.z_index = 0

    -- Animation data
    self.anim_size = 1
    self.anim_timer = 0
    self.anim_frame = 0
    self.anim_speed = 1 / 12

    getmetatable(Entity).init(self, data)
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
        sprite.drawSprite(self:spriteFrame(), self.x, self.y)
    end
end

function Entity:spriteFrame()
    return self.sprite + self.anim_frame
end

function Entity:getcr()
    return pos2cr(self.x, self.y)
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
function PhysEntity:step(dt)
    self:updateVectors(dt)
    local nx = self.x + self.velx * dt
    local ny = self.y + self.vely * dt
    self.grounded = false

    -- Check entity collision
    for i, entity in ipairs(game.entities) do
        if entity ~= self and entity.collision then
            nx, ny = self:projectCollision(nx, ny, entity)
        end
    end

    -- Check player collision
    nx, ny = self:projectCollision(nx, ny, player)

    -- Set new position after collision
    self.x = nx
    self.y = ny
end

function PhysEntity:projectCollision(nx, ny, entity)
    local l, t, r, b = entity:getbb()

    -- Check x axis collisions
    if overlaps(self.y, self.y + self.h, t, b) then
        if self.x + self.w <= l and nx + self.w > l then
            if entity.solid then
                nx = l - self.w
                self.velx = 0
            end
            self:collideWith(entity, LEFT)
        elseif self.x >= r and nx < r then
            if entity.solid then
                nx = r
                self.velx = 0
            end
            self:collideWith(entity, RIGHT)
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
        elseif self.y >= b and ny < b then
            if entity.solid then
                ny = b
                self.vely = 0
            end
            self:collideWith(entity, BOTTOM)
        end
    end

    return nx, ny
end


function PhysEntity:collideWith(target, side)
end