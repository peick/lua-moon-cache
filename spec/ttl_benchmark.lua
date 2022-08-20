-- luajit spec/ttl_benchmark.lua
-- warmup:   1415k puts/sec
-- round  1:   1510k puts/sec
-- round  2:   1374k puts/sec
-- round  3:   4784k puts/sec
-- round  4:   4334k puts/sec
-- round  5:   3989k puts/sec

-- lua spec/ttl_benchmark.lua
-- warmup:    542k puts/sec
-- round  1:    532k puts/sec
-- round  2:    605k puts/sec
-- round  3:   1159k puts/sec
-- round  4:   1176k puts/sec
-- round  5:   1174k puts/sec

local Cache = require('cache.ttl')

local cache = Cache:new{ttl = 60}

local KEYS = 1000 * 100
local ITERATIONS = 5

local function feed(cache)
    local start_time = os.clock()
    for i=1,KEYS do
        cache:put(i, i)
    end
    local duration = os.clock() - start_time
    local puts_per_second = KEYS / duration

    return puts_per_second
end

local puts_per_second = feed(Cache:new{ttl = 60})
print(string.format('warmup: %6.0fk puts/sec', puts_per_second / 1000))

cache = Cache:new{ttl = 1}
for i=1,ITERATIONS do
    local puts_per_second = feed(cache)
    print(string.format('round %2d: %6.0fk puts/sec', i, puts_per_second / 1000))
end
