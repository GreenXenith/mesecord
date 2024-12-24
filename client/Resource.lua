local Class = include("utils/class")

local Resource = Class()

Resource.__init = function(self, manager)
    self._manager = manager
end

Resource.fetch = function(self, method, uri, data, callback)
    self._manager:fetch(method, uri, data, callback)
end

return Resource
