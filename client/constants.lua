local constants = {}

constants.API_VERSION = 10

constants.API_URL = "https://discord.com/api/v" .. constants.API_VERSION
constants.GET_GATEWAY_URL = "https://discord.com/api/gateway"

constants.CONNECT_TIMEOUT = 30

constants.USER_AGENT = {
    os = "luanti",
    browser = "luanti-mesecord",
    device = "luanti-mesecord",
}

constants.DEFAULT_INTENTS = 3243773 -- All non-privileged intents

-- https://discord.com/developers/docs/events/gateway-events
constants.OPCODES = {
    DISPATCH                  = 0,  -- Receive
    HEARTBEAT                 = 1,  -- Send/Receive
    IDENTIFY                  = 2,  -- Send
    PRESENCE_UPDATE           = 3,  -- Send
    VOICE_STATE_UPDATE        = 4,  -- Send
    RESUME                    = 6,  -- Send/Receive
    RECONNECT                 = 7,  -- Receive
    REQUEST_GUILD_MEMBERS     = 8,  -- Send
    INVALID_SESSION           = 9,  -- Receive
    HELLO                     = 10, -- Receive
    HEARTBEAT_ACK             = 11, -- Receive
    REQUEST_SOUNDBOARD_SOUNDS = 31, -- Send
}

return constants
