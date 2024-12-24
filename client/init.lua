local json = include("utils/json")
local http = include("core.http")

local Class = include("utils/class")
local Events = include("utils/Events")

local ResourceManager = include("client/ResourceManager")
local Gateway = include("client/Gateway")

local constants = include("client/constants")

---

local Client = Class(Events)

Client.__init = function(self)
    self._gateway = Gateway()

    self._gateway:on(constants.OPCODES.DISPATCH, function(data, event_type)
        self:emit(event_type, data)
    end)

    self:on("READY", function(data)
        self.user = data.user
        self:emit("ready")
    end)

    self:on("MESSAGE_CREATE", function(data)
        self:emit("message", self.resources:Message(data, self._token))
    end)
end

-- Intent toggling (required for privileged intents)
Client.enable_intent = function(self, intent_bit)
    self._gateway.intents = bit.bor(self._gateway.intents, intent_bit)
end

Client.disable_intent = function(self, intent_bit)
    self._gateway.intents = bit.band(self._gateway.intents, bit.bnot(intent_bit))
end

-- Fetch/connect to gateway url
Client.login = function(self, token, callback)
    callback = callback or function() end

    self.resources = ResourceManager(token)

    -- TODO: Make these errors useful
    http.fetch({url = constants.GET_GATEWAY_URL}, function(res)
        if res.succeeded then
            local gateway_url = json.decode(res.data).url .. "/?v=" .. constants.API_VERSION .. "&encoding=json"
            local success, err = self._gateway:connect(gateway_url, token)

            if not success then
                return callback(false, "Gateway connection failed: " .. err)
            end
        else
            return callback(false, "Error " .. res.code .. " fetching gateway URL: " .. res.data)
        end

        return callback(true)
    end)
end

-- Create channel resource from id (naiive)
Client.get_channel = function(self, channel_id)
    return self.resources:Channel({id = channel_id})
end

return Client
