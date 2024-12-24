---
--- ResourceManager spawns resources passing self to each resource so resources may refer to the manager to fetch.
--- The manager stores headers, handles fetch payloads, and may handle ratelimiting in the future.
---

local Class = include("utils/class")

local json = include("utils/json")
local http = include("core.http")

local constants = include("client/constants")

local ResourceManager = Class()

ResourceManager.__init = function(self, token)
    self._headers = {
        "Authorization: Bot " .. token,
        "Content-Type: application/json",
    }
end

-- TODO: Makes sure this method is safe
ResourceManager.fetch = function(self, method, uri, data, callback)
    http.fetch({
        method = method,
        url = constants.API_URL .. uri,
        data = json.encode(data),
        extra_headers = self._headers,
    }, callback or function() end)
end

local create_resource = function(resource)
    return function(self, o)
        return resource:apply(o, self)
    end
end

for _, name in pairs(core.get_dir_list(core.get_modpath(core.get_current_modname()) .. "/client/resources/"), false) do
    ResourceManager[name:sub(1, -5)] = create_resource(include("client/resources/" .. name))
end

return ResourceManager
