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
    self.solid = true
    self.alive = true

    getmetatable(Entity).init(self, data)
end


function Entity:update(dt)

end

function Entity:draw()

end



PhysEntity = Entity:extend()

function PhysEntity:init(data)
    self.awake = true
    self.last_x = 0
    self.last_y = 0
    self.velx = 0
    self.vely = 0

    getmetatable(PhysEntity).init(self, data)
end

function PhysEntity:update(dt)
    getmetatable(PhysEntity).update(self, dt)

    if self.awake then
        self.last_x = self.x
        self.last_y = self.y
        self.vely = self.vely + GRAVITY * dt
        self.y = self.y + self.vely * dt
    end
end


