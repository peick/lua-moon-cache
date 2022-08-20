# moon-cache

A lua library for caching:
- TTL cache

100% lua code, works with lua >= 5.1 and luajit

## Installation

```
luarocks install moon-cache
```

## Usage

```
local TTLCache = require('moon.cache.ttl')

cache = TTLCache:new{ttl = 60}
-- cache = TTLCache:new{ttl = 60, time = os.time}

cache:put('some-key', 'some-value')
local value = cache:get('some-key')
```

There is no need to explicitly do a cleanup by calling `cache:expire()`.
A cleanup is performed on every `cache:put`.
