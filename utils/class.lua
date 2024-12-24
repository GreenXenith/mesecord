---
--- Class type with inheritance.
--- Parent constructors are called automatically using the top-level arguments.
--- (This might not be a good idea, but it works for now)
---

--[[

-- Example Class

local BaseClass = Class()

-- Constructor
BaseClass.__init = function(self)
    self.foo = "foo"
end

BaseClass.print = function(self)
    print(self.foo)
end

local SuperClass = Class(BaseClass)

-- Super constructor ran after base constructor
SuperClass.__init = function(self)
    self.foo = self.foo .. "bar"
end

SuperClass:print() -- Prints "foobar"

--]]

return function(inherit)
    return setmetatable({
        apply = function(self, o, ...)
            setmetatable(o, {__index = self})

            if inherit and inherit.__init then
                inherit.__init(o, ...)
            end

            if o.__init then
                o:__init(...)
            end

            return o
        end,
    }, {
        __call = function(self, ...)
            return self:apply({}, ...)
        end,
        __index = inherit,
    })
end
