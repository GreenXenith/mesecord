-- https://discord.com/developers/docs/resources/channel

local Class = include("utils/class")
local Resource = include("client/Resource")

local Channel = Class(Resource)

Channel.send = function(self, message)
    self._manager:fetch("POST", ("/channels/%s/messages"):format(self.id), message)
end

return Channel
