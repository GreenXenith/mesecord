# Mesecord
_Discord API library in Lua for Luanti_

Proof of concept. Missing a lot of features. Until performance and security can be proven, maybe don't use this.  
(Very) loosely inspired by https://github.com/satom99/litcord.

> [!WARNING]
> Does NOT support Windows currently. See [Todo#Websockets](#websockets).


## Installation
Clone or [download](https://github.com/GreenXenith/mesecord/archive/refs/heads/master.zip) the mod:
```bash
cd mods_directory
git clone https://github.com/GreenXenith/mesecord.git
```

Install [`http`](https://github.com/daurnimator/lua-http):
```
sudo apt install luarocks
luarocks install http
```

Add `mesecord` to trusted mods:
```
secure.trusted_mods = mesecord
```


## Using the Library
> [!WARNING]
> Extremely limited right now. Most features are incomplete or missing.

Your mod must:
* Depend on `mesecord`
* Be in `secure.http_mods` (or trusted)

See [examples/chat_bridge.lua](examples/chat_bridge.lua)

### API
This API is extremely limited right now and subject to change without notice.

`mesecord.Client()` -> `Client`  
Returns a new `Client` object.

#### `Client`

`Client:enable_intent(intent: mesecord.INTENTS)`
* `intent`: `mesecord.INTENTS` bit

Enables the given gateway intent. Privileged intents (`GUILDS`, `GUILD_PRESENCES`, and `MESSAGE_CONTENT`) must be explicitly enabled. See https://discord.com/developers/docs/events/gateway#list-of-intents.

`Client:disable_intent(intent: mesecord.INTENTS)`
* `intent`: `mesecord.INTENTS` bit

Disables the given gateway intent.

`Client:login(token: string, callback?: function)`
* `token`: Your bot's token
* `callback`: Optional callback will be passed `(success: bool, err: string)`

`Client:get_channel(id: string)` -> `Channel`
* `id`: The snowflake ID of the channel

Returns an extremely basic `Channel` object (does not fetch channel data, can only send messages).

`Client:on(event: string, callback: function)`
* `event`: An event name

When the `event` occurs, `callback` will be called with data for that events.  

#### Client events:

* `ready`: The client has connected and may start sending/receiving events
* `message` -> `Message`: A message was received in a channel; callback data is a `Message`

#### `Channel`

May represent a [Discord Channel object](https://discord.com/developers/docs/resources/channel#channel-object) or simply be a wrapper around an ID to send messages.

`Channel:send(message: table)`
* `message`: A valid [Message object](https://discord.com/developers/docs/resources/message#message-object)

Sends the given message to the channel.

#### `Message`

Represents a [Discord Message object](https://discord.com/developers/docs/resources/message#message-object). The `channel` property of the Message will be a `Channel` object.

`Message:reply(message: table)`
* `message`: A valid [Message object]((https://discord.com/developers/docs/resources/message#message-object))

Replies to the parent message with the given message.



## Todo
### Ratelimits
Discord imposes ratelimits for the gateway and HTTP resource endpoint (separately) and certain resource types may also have separate ratelimits. It would be nice to safeguard against exceeding the ratelimits and possibly queue events.

### JSON
The Luanti JSON encoder is broken. It has no NULL type, encodes empty tables as NULL (instead of `{}`), and may encode integers with a decimal part. This is not acceptable for handling JSON consumed by endpoints which may have stricter types (and are following the spec properly https://json-schema.org/draft/2020-12/json-schema-core#section-6.3).

> Some programming languages and parsers use different internal representations for floating point numbers than they do for integers.
> 
> For consistency, integer JSON numbers SHOULD NOT be encoded with a fractional part.

I am currently using https://github.com/Vurv78/qjson.lua in place of the Luanti encoder. It should be mostly spec-compliant, but https://github.com/grafi-tt/lunajson is a viable alternative if that proves otherwise. It would also be cool if the Luanti JSON encoder were fixed.

### Websockets
Currently uses `http.websocket` provided by [lua-http](https://github.com/daurnimator/lua-http). This library is well-supported and up-to-date, but unfortunately it relies on [cqueues](https://github.com/wahern/cqueues) to implement asyncronous behavior (does not support Windows). I am unsure if the cqueues system is actively utilized in the websocket portion of the library or just passively supported. If this can run on Windows, please open an issue.

I am also not confident in the asyncronicity of the websocket system as `http.websocket` uses a blocking while-loop when receiving socket frames which seems wrong to me, though there may be a cqueue thing I am missing.

### Error handling
Some errors may be unhandled (disconnects, failed HTTP requests). These should be gracefully returned to the caller to handle themselves.

### Promises
Callbacks are not a fantastic model, so it may be worth converting everything to a Promise-like system.


## License
Licensed under the [MIT License](LICENSE.txt).

[utils/json.lua](utils/json.lua) ([https://github.com/Vurv78/qjson.lua](qjson.lua)): MIT Copyright (c) 2023 Vurv
