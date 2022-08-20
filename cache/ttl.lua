local TTLCache = {}

-- Options:
--   ttl: time-to-live for keys in seconds, default: 60
--   time: a function to return the timestamp, default: os.time
function TTLCache:new(opts)
    -- items have internal format
    -- { ts : <timestamp of timeout>, next: <next item>, key: <key>, value: <value> }
    opts = opts or {}
    local o = {
        ttl = opts.ttl or 60,
        time = opts.time or os.time,
        items = {},

        -- first item
        first = nil,

        -- last item
        last = nil,
    }

    setmetatable(o, self)
    self.__index = self

    return o
end

-- Remove expired items
function TTLCache:expire()
    local now = self.time()
    local item = self.first

    while item do
        if now >= item.ts then
            self.first = item.next
            self.items[item.key] = nil

            item = item.next
        else
            return
        end
    end
end

function TTLCache:put(key, value)
    -- If key is already present in items, then it moves the modified item to the tail of the linked list
    local item = self.items[key]
    if item then
        if item.prev then
            item.prev.next = item.next
        end
        if item.next then
            item.next.prev = item.prev
        end
    else
        item = { key = key }
        self.items[key] = item

        if not self.first then
            self.first = item
        end
    end

    item.value = value
    item.ts = self.time() + self.ttl

    if self.last then
        self.last.next = item
        item.prev = self.last
    end
    self.last = item

    self:expire()
end

function TTLCache:get(key)
    local item = self.items[key]
    if not item then
        return
    end

    local now = self.time()
    if now >= item.ts then
        return
    end

    return item.value
end

local function unstable_iterator(state)
    local now = state.time()

    while state.item and now >= state.item.ts do
        state.item = state.item.next
    end

    if not state.item then
        return
    end

    local key = state.item.key
    local value = state.item.value
    state.item = state.item.next
    return key, value
end

--- An iterator for items in the cache.
---
--- In situations where the items are consumed too slow it may happen that items expire or gets updated.
--- The iterator may skip some old expired items, may repeat already iterated keys or even skip not expired keys.
---
--- To overcome this drawback this iterator can be used with option "stable = true" to return a stable snapshot of
--- the items. For this it makes a copy of all key value pairs before starting the iterator.
function TTLCache:pairs(o)
    o = o or {}

    local now = self.time()
    if o.stable then
        local items = {}
        for k, item in pairs(self.items) do
            if now < item.ts then
                items[k] = item.value
            end
        end
        return pairs(items)
    end

    return unstable_iterator, {item = self.first, time = self.time}
end

return TTLCache
