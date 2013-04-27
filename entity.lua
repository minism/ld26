DataObject = Object:extend()
DataObject.defaults = {}

function DataObject:init(data)
    _.extend(self, data or {})
end


Entity = DataObject:extend()

function Entity:init(data)
    self.x = 0
    self.y = 0
    self.solid = true

    getmetatable(Entity).init(self, data)
end