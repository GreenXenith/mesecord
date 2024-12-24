---
--- Example chat bridge using Mesecord
---

-- Read configuration
local CONFPATH = core.get_worldpath() .. "/mesecord_example_bridge.conf"
local conf = Settings(CONFPATH)

local conf_get = function(key, default)
    return assert(conf:get(key) or default, ("%s must be set in %s"):format(key, CONFPATH))
end

local config = {
    guild_name = conf_get("guild_name", "discord"), -- Optional
    server_name = conf_get("server_name", "luanti"), -- Optional
    channel_id = conf_get("channel_id"),
    token = conf_get("token"),
}

local client = mesecord.Client()

-- Explicitly enable privileged intents
client:enable_intent(mesecord.INTENTS.MESSAGE_CONTENT)

-- Discord -> Luanti
client:on("message", function(message)
    -- Only relay messages from the configured channel sent by anyone other than self
    if message.channel_id == config.channel_id and message.author.id ~= client.user.id then
        local msg = ("<%s@%s> %s"):format(message.author.username, config.guild_name, message.content)
        core.chat_send_all(msg)
        core.log("action", "DISCORD CHAT: " .. msg)
    end
end)

-- Luanti -> Discord
core.register_on_chat_message(function(name, message)
    client:get_channel(config.channel_id):send({content = ("<%s@%s> %s"):format(name, config.server_name, message)})
end)

client:on("ready", function()
    core.log("action", "Mesecord Bridge logged in as " .. client.user.username)
end)

-- Init
client:login(config.token)
