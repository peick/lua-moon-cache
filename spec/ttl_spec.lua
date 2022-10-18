local TTLCache = require('cache.ttl')

describe('ttl cache', function()
    local function make_timer()
        -- 2000-01-01 00:00:00
        local now = 946684800

        local function timer(increase)
            increase = increase or 0
            now = now + increase
            return now
        end
        return timer
    end

    it('put nil value', function()
        local c = TTLCache:new { ttl = 60, time = make_timer() }
        c:put(42, nil)
        local v = c:get(42)
        assert.is_nil(v)
    end)

    it('put primitive value', function()
        local c = TTLCache:new { ttl = 60, time = make_timer() }

        c:put(41, 0)
        c:put(42, 1000)
        c:put(43, '')
        c:put(44, 'abc')
        c:put(45, true)
        c:put(46, false)

        assert.same(c:get(41), 0)
        assert.same(c:get(42), 1000)
        assert.same(c:get(43), '')
        assert.same(c:get(44), 'abc')
        assert.same(c:get(45), true)
        assert.same(c:get(46), false)
    end)

    it('builds double linked list', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 60, time = timer }

        c:put(42, 1000)
        c:put(43, 1001)
        c:put(44, 1002)

        local i42 = c.items[42]
        local i43 = c.items[43]
        local i44 = c.items[44]

        assert.equal(i42.next, i43)
        assert.equal(i43.next, i44)
        assert.is_nil(i44.next)

        assert.is_nil(i42.prev)
        assert.equal(i43.prev, i42)
        assert.equal(i44.prev, i43)
    end)

    it('gets expired item', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 1, time = timer }

        c:put(42, 1000)
        assert.same(c:get(42), 1000)

        timer(5)
        assert.is_nil(c:get(42))
    end)

    it('gets removed item', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 1, time = timer }

        c:put(42, 1000)
        assert.same(c:get(42), 1000)

        c:remove(42)
        assert.is_nil(c:get(42))
    end)

    it('sets new ttl', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 60, time = timer }

        c:put(42, 1000)
        assert.same(c:get(42), 1000)

        -- decrease ttl
        c:set_ttl(30)
        timer(20)
        assert.same(c:get(42), 1000)

        timer(20)
        assert.is_nil(c:get(42))

        -- increase ttl
        c:put(99, 1001)
        c:set_ttl(120)

        timer(110)
        assert.same(c:get(99), 1001)
    end)

    it('expires many items', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 300, time = timer }

        for key = 1, 100 do
            c:put(key, key * 2)
            timer(1)
        end

        for key = 1, 100 do
            assert.same(c:get(key), key * 2)
        end

        timer(300)
        for key = 1, 100 do
            assert.is_nil(c:get(key))
        end
    end)

    it('updates', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 1, time = timer }

        c:put(42, 1000)

        c:put(42, 1001)
        assert.same(c:get(42), 1001)

        c:put(42, nil)
        assert.is_nil(c:get(42))

        c:put(42, 1002)
        assert.same(c:get(42), 1002)
    end)

    it('updates and expires', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 1, time = timer }

        c:put(42, 1000)
        c:put(42, 1001)
        timer(2)

        assert.is_nil(c:get(42))
    end)

    it('expires and updates', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 1, time = timer }

        c:put(42, 1000)
        timer(2)
        c:put(42, 1001)

        assert.same(c:get(42), 1001)
    end)

    it('updates randomly', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 1, time = timer }
        local ref = {}

        local function feed()
            for _ = 1, 100 do
                local key = math.random(1, 10)
                local value = math.random(1, 10)
                c:put(key, value)
                ref[key] = value
            end
        end

        local function check()
            for key, value in pairs(ref) do
                assert.same(c:get(key), value)
            end
        end

        for _ = 1, 10 do
            feed()
            check()
        end
    end)

    it('iterates unstable', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 60, time = timer }

        c:put('a', 1)
        c:put('b', 2)
        c:put('c', 3)
        c:put('d', 4)

        local result = {}
        for k, v in c:pairs() do
            result[k] = v
        end

        local expect = {
            a = 1,
            b = 2,
            c = 3,
            d = 4,
        }

        assert.same(result, expect)
    end)

    it('iterates unstable slowly', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 60, time = timer }

        c:put('a', 1)
        c:put('b', 2)
        c:put('c', 3)
        c:put('d', 4)

        local result = {}
        for k, v in c:pairs() do
            result[k] = v
            timer(30)
        end

        local expect = {
            a = 1,
            b = 2,
        }

        assert.same(result, expect)
    end)


    it('iterates stable', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 60, time = timer }

        c:put('a', 1)
        c:put('b', 2)
        c:put('c', 3)
        c:put('d', 4)

        local result = {}
        for k, v in c:pairs{stable = true} do
            result[k] = v
        end

        local expect = {
            a = 1,
            b = 2,
            c = 3,
            d = 4,
        }

        assert.same(result, expect)
    end)

    it('iterates stable slowly', function()
        local timer = make_timer()
        local c = TTLCache:new { ttl = 60, time = timer }

        c:put('a', 1)
        c:put('b', 2)
        c:put('c', 3)
        c:put('d', 4)

        local result = {}
        for k, v in c:pairs{stable = true} do
            result[k] = v
            timer(30)
        end

        local expect = {
            a = 1,
            b = 2,
            c = 3,
            d = 4,
        }

        assert.same(result, expect)
    end)
end)
