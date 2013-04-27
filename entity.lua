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

    getmetatable(Entity).init(self, data)
end


function Entity:update(dt)

end

function Entity:draw()

end



PhysEntity = Entity:extend()

function PhysEntity:init(data)
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
        if entity ~= self and entity.solid then
            local l, t, r, b = entity:getbb()

            -- Check x axis collisions
            if self.y + self.h > t and self.y < b then
                if self.x + self.w <= l and nx + self.w > l then
                    nx = l - self.w
                    self:collided(entity, LEFT)
                    self.velx = 0
                elseif self.x > r and nx <= r then
                    nx = r
                    self:collided(entity, RIGHT)
                    self.velx = 0
                end
            end

            -- Check y axis collisions
            if self.x + self.w > l and self.x < r then
                if self.y + self.h <= t and ny + self.h > t then
                    ny = t - self.h
                    self:collided(entity, TOP)
                    self.vely = 0
                    self.grounded = true
                elseif self.y > b and ny <= b then
                    ny = b
                    self:collided(entity, BOTTOM)
                    self.vely = 0
                end
            end
        end
    end

    -- Set new position after collision
    self.x = nx
    self.y = ny
end

function PhysEntity:collided(entity, direction)

end
