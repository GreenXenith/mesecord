---
--- Insecure variables must be initialized here, but other modules need to use them. A custom include function will
--- allow these variables to be passed safely, and a custom env allows local modules to utilize the include function
--- without using a global variable. Use insecure environment methods to ensure they are unaltered.
---

local MODNAME = "mesecord" -- While core.get_current_modname() is cleaner, this is safer
local MODPATH = core.get_modpath(MODNAME)

---
--- Security checks
---

-- Obtain insecure environment FIRST so we can use safe methods
local ie = core.request_insecure_environment()

-- Passing the insecure environment directly to assert would be a security vulnerability! Use a bool from ~= nil
assert(ie ~= nil, ("Add %s to secure.trusted_mods"):format(MODNAME))

-- Ensure core.get_current_modname() is returning valid values (restricted globals check modnames later)
-- Without this, a mod may claim it is a HTTP mod when accesing restricted globals
ie.assert(
    core.get_current_modname() == MODNAME,
    ("\n\n" .. [[
        !!! POTENTIAL HIJACK !!!
        core.get_current_modname() returned faulty name: '%s'
        Expected name: '%s'
        A malicious mod may be interfering!
    ]]):format(core.get_current_modname(), "mesecord")
)

-- Verify the modpath, just in case
-- Without this, a mod may intercept the include function and any involved environments or variables
ie.assert(
    ie.string.sub(MODPATH, -(ie.string.len(MODNAME) + 6)) == DIR_DELIM .. "mods" .. DIR_DELIM .. MODNAME,
    ("\n\n" .. [[
        !!! POTENTIAL HIJACK !!!
        core.get_modpath() returned faulty path: '%s'
        Expected path: '%s'
        A malicious mod may be interfering!
    ]]):format(MODPATH, MODPATH:sub(1, MODPATH:find("mods" .. DIR_DELIM) + 4) .. MODNAME)
)

---
--- Insecure APIs available to local environment (http, websocket)
---

local insecure_modules = {}

insecure_modules["core.http"] = core.request_http_api()
assert(insecure_modules["core.http"] ~= nil, ("??? HTTP API somehow missing even though trusted ???"):format(MODNAME))

do -- Insecure require http.websocket
    local dbg = ie.debug

    dbg.sethook()

    local old_thread_env = ie.getfenv(0)
    local old_string_metatable = dbg.getmetatable("")

    ie.setfenv(0, ie)
    dbg.setmetatable("", {__index = ie.string})

    local ok, websocket = ie.pcall(ie.require, "http.websocket")

    ie.setfenv(0, old_thread_env)
    dbg.setmetatable("", old_string_metatable)

    ie.assert(ok, websocket)

    insecure_modules["http.websocket"] = websocket
end

-- Local environment all local modules will use
local local_env = ie.setmetatable({}, {__index = _G})

local_env.include = function(path, ...)
    if insecure_modules[path] then
        return insecure_modules[path]
    end

    if path:sub(-1) == "/" then
        path = path .. "init.lua"
    elseif path:sub(-4) ~= ".lua" then
        path = path .. ".lua"
    end

    return ie.setfenv((ie.assert(ie.loadfile(MODPATH .. "/" .. path))), local_env)(...)
end

---
--- Global table with protected section (only HTTP mods may access protected globals at loadtime)
---

local library, library_protected = {}, {}
local http_mods = {}
local core_get_current_modname = core.get_current_modname -- Protect against mods spoofing name

do
    -- Build HTTP mod index
    for _, modname in pairs((core.settings:get("secure.http_mods") or ""):split(",")) do
        http_mods[modname] = true
    end

    for _, modname in pairs((core.settings:get("secure.trusted_mods") or ""):split(",")) do
        http_mods[modname] = true
    end

    ie.setmetatable(library, {
        __index = function(t, k) -- Index protected library if allowed
            return rawget(t, k) or (http_mods[core_get_current_modname()] and library_protected[k])
        end,
        __metatable = {}, -- Hide this metatable
    })
end

---
--- Globals
---

library_protected.Client = local_env.include("client/")

library.INTENTS = {
    GUILDS                        = bit.lshift(1, 0),
    GUILD_MEMBERS                 = bit.lshift(1, 1), -- Privileged
    GUILD_MODERATION              = bit.lshift(1, 2),
    GUILD_EXPRESSIONS             = bit.lshift(1, 3),
    GUILD_INTEGRATIONS            = bit.lshift(1, 4),
    GUILD_WEBHOOKS                = bit.lshift(1, 5),
    GUILD_INVITES                 = bit.lshift(1, 6),
    GUILD_VOICE_STATES            = bit.lshift(1, 7),
    GUILD_PRESENCES               = bit.lshift(1, 8), -- Privileged
    GUILD_MESSAGES                = bit.lshift(1, 9),
    GUILD_MESSAGE_REACTIONS       = bit.lshift(1, 10),
    GUILD_MESSAGE_TYPING          = bit.lshift(1, 11),
    DIRECT_MESSAGES               = bit.lshift(1, 12),
    DIRECT_MESSAGE_REACTIONS      = bit.lshift(1, 13),
    DIRECT_MESSAGE_TYPING         = bit.lshift(1, 14),
    MESSAGE_CONTENT               = bit.lshift(1, 15), -- Privileged
    GUILD_SCHEDULED_EVENTS        = bit.lshift(1, 16),
    AUTO_MODERATION_CONFIGURATION = bit.lshift(1, 20),
    AUTO_MODERATION_EXECUTION     = bit.lshift(1, 21),
    GUILD_MESSAGE_POLLS           = bit.lshift(1, 24),
    DIRECT_MESSAGE_POLLS          = bit.lshift(1, 25),
}

-- Expose globals
rawset(_G, MODNAME, library)

-- Example
-- dofile(MODPATH .. "/examples/chat_bridge.lua")
