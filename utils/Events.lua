---
--- Simple event handler
---

local Class = include("utils/class")

---

local Events = Class()

Events.__init = function(self)
    self._callbacks = {}
end

Events.on = function(self, event, callback)
    if not self._callbacks[event] then
        self._callbacks[event] = {}
    end

    table.insert(self._callbacks[event], callback)
end

Events.emit = function(self, event, ...)
    if self._callbacks[event] then
        for _, callback in pairs(self._callbacks[event]) do
            callback(...)
        end
    end
end

return Events
