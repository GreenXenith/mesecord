-- https://discord.com/developers/docs/resources/message

local Class = include("utils/class")
local Resource = include("client/Resource")

local Message = Class(Resource)

Message.__init = function(self)
    self.channel = self._manager:Channel({id = self.channel_id})
end

Message.reply = function(self, message)
    message.message_reference = {
        type = 0,
        message_id = self.id,
    }

    self.channel:send(message)
end

return Message
