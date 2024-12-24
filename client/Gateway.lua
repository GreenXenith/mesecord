---
--- The Gateway is in charge of connecting to the Discord Gateway API via WebSocket. It handles opcodes, heartbeats,
--- identification, and events. See https://discord.com/developers/docs/events/gateway
---

local Class = include("utils/class")
local Events = include("utils/Events")

local json = include("utils/json")

local constants = include("client/constants")

local websocket = include("http.websocket")

---

local Gateway = Class(Events)

Gateway.__init = function(self)
    self.token = ""
    self.identified = false

    self.last_sequence_number = nil
    self.heartbeat_interval = nil

    self.intents = constants.DEFAULT_INTENTS

    core.register_globalstep(function()
        for event in self:receive() do
            self:emit(event.op, event.d, event.t, event.s)
        end
    end)

    self:_setup_callbacks()
end

Gateway.connect = function(self, url, token)
    self.token = token
    self.gateway_url = url
    self.socket = websocket.new_from_uri(url)
    return self.socket:connect(constants.CONNECT_TIMEOUT)
end

Gateway.receive = function(self)
    local frame
    return function()
        frame = self.socket and self.socket:receive(0)
        return frame and json.decode(frame)
    end
end

Gateway.send = function(self, opc, data)
    self.socket:send(json.encode({
        op = opc,
        d = data,
    }))
end

Gateway.close = function(self)
    return self.socket:close()
end

Gateway.reconnect = function(self)
    self.socket:close()
    local success, err = self:connect(self.resume_url, self.token)

    if success then
        self:send(constants.OPCODES.RESUME, {
            token = self.token,
            session_id = self.session_id,
            seq = self.last_sequence_number,
        })
    end

    return success, err
end

Gateway._send_heartbeat = function(self)
    self:send(constants.OPCODES.HEARTBEAT, self.last_sequence_number or json.NULL)
end

Gateway._loop_heartbeat = function(self)
    self:_send_heartbeat()
    core.after(self.heartbeat_interval, self._loop_heartbeat, self)
end

-- Listen for receive events
-- Note: opcode RESUME is not currently handled because I don't know if it's actually important
-- https://discord.com/developers/docs/events/gateway-events#resumed
-- https://discord.com/developers/docs/events/gateway#preparing-to-resume
Gateway._setup_callbacks = function(self)
    local opcodes = constants.OPCODES

    self:on(opcodes.HELLO, function(data)
        self.heartbeat_interval = data.heartbeat_interval / 1000

        -- Supposed to wait `heartbeat_interval * math.random()` but I don't think anyone does that (takes too long)
        core.after(math.random(), self._loop_heartbeat, self)
    end)

    self:on(opcodes.HEARTBEAT_ACK, function()
        if not self.identified then
            self:send(opcodes.IDENTIFY, {
                token = self.token,
                intents = self.intents,
                properties = constants.USER_AGENT,
            })
        end
    end)

    self:on(opcodes.INVALID_SESSION, function(data)
        if data then
            self:reconnect()
        else
            self:close()
            self.identified = false
            self:connect(self.gateway_url, self.token)
        end
    end)

    self:on(opcodes.RECONNECT, function()
        self:reconnect()
    end)

    self:on(opcodes.DISPATCH, function(data, event_name, seq)
        self.last_sequence_number = seq

        if event_name == "READY" then
            self.identified = true
            self.session_id = data.session_id
            self.resume_url = data.resume_gateway_url
        end
    end)

    self:on(opcodes.HEARTBEAT, function()
        self:_send_heartbeat()
    end)
end

return Gateway
