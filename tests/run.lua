package.path = "./?.lua;" .. package.path
local Game = require("src.Game")
local passed, failed = 0, 0
local function test(name, run)
    local ok, err = pcall(run)
    if ok then passed = passed + 1; print("PASS " .. name)
    else failed = failed + 1; print("FAIL " .. name .. ": " .. tostring(err)) end
end
local function equal(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function near(a, b, tolerance) assert(math.abs(a - b) < (tolerance or 0.02), a .. " ~= " .. b) end
local function copying(seed)
    local g = Game.new(seed or 100)
    g:start()
    return g
end
local function fault(g)
    while #g:badTracks() == 0 do g:update(0.1, false) end
    assert(g:beginRepair())
end
local function perfect(g)
    local r = g.repair
    -- Advance real simulation to the centre instead of assigning a success state.
    local untilCenter = r.center * r.period - r.elapsed
    assert(untilCenter >= 0)
    g:update(untilCenter, false)
    g:hit()
end

test("ready does not consume the shift", function()
    local g = Game.new(10); g:update(12, true)
    equal(g.phase, "ready"); equal(g.time, 110); equal(g.cursor, 0)
end)
test("normal copying advances at 12 tracks per second", function()
    local g = copying(); g:update(5, false)
    near(g.cursor, 60, 2); near(g.time, 105)
end)
test("same seed makes same faults", function()
    local a, b = copying(42), copying(42)
    a:update(10, false); b:update(10, false)
    equal(table.concat(a.tracks), table.concat(b.tracks))
end)
test("safe tracks cannot be retried", function()
    local g = copying(); g:update(0.5, false)
    equal(g:beginRepair(1), false); equal(g.repair, nil)
end)
test("perfect retry restores track and raises combo", function()
    local g = copying(); fault(g)
    local index, score, cursor = g.repair.index, g.score, g.cursor
    perfect(g)
    equal(g.tracks[index], "fixed"); equal(g.combo, 1); equal(g.score, score + 150)
    equal(g.perfects, 1); equal(g.cursor, cursor)
end)
test("green edge is a normal successful rescue", function()
    local g = copying(); fault(g)
    g:update(g.repair.period * (g.repair.center + g.repair.width * 0.35), false)
    local score = g.score; g:hit()
    equal(g.rescued, 1); equal(g.perfects, 0); equal(g.score, score + 80)
end)
test("miss costs integrity and clears combo", function()
    local g = copying(); fault(g); g.combo = 4; g:hit()
    equal(g.health, 4); equal(g.combo, 0); equal(g.misses, 1)
    assert(#g:badTracks() > 0)
end)
test("five missed retries lose the run", function()
    local g = copying(); fault(g)
    for i = 1, 5 do if not g.repair then g:beginRepair() end; g:hit() end
    equal(g.phase, "lost"); equal(g.health, 0)
end)
test("pause freezes time heat and calibration", function()
    local g = copying(); fault(g); g:togglePause()
    local time = g.time; g:update(5, true); g:hit()
    near(g.time, time); near(g.repair.elapsed, 0); equal(g.health, 5)
    g:togglePause(); g:update(0.25, false); assert(g.repair.elapsed > 0)
end)
test("cancel retry resumes copying without a penalty", function()
    local g = copying(); fault(g); assert(g:cancelRepair())
    local cursor = g.cursor; g:update(1, false)
    assert(g.cursor > cursor); equal(g.health, 5)
end)
test("turbo copies faster and gains heat", function()
    local g = copying(); g:update(2, true)
    assert(g.cursor >= 51); near(g.heat, 52, 0.3)
end)
test("overheat stalls and penalizes then cools", function()
    local g = copying(); g:update(4, true)
    equal(g.health, 4); assert(g.stall > 1)
    local cursor = g.cursor; g:update(1, false); equal(cursor, g.cursor)
    g:update(2, false); equal(g.stall, 0); assert(g.heat < 45)
end)
test("uncorrected disk cannot advance", function()
    local g = copying(); g:update(15, false)
    equal(g.cursor, 160); assert(#g:badTracks() > 0); equal(g.phase, "copying")
end)
test("timeout loses and no subsequent input resurrects it", function()
    local g = copying(); g:update(111, false)
    equal(g.phase, "lost"); equal(g.time, 0)
    g:start(); g:hit(); equal(g.phase, "lost")
end)
test("arrows cycle actual damaged tracks", function()
    local g = copying(); g:update(15, false)
    local first = g.selected; g:cycle(1); assert(g.selected ~= first)
    g:cycle(-1); equal(g.selected, first)
end)
test("frame rate independent normal and turbo progression", function()
    for _, boost in ipairs({false, true}) do
        local a, b = copying(431), copying(431)
        for _ = 1, 300 do a:update(1 / 30, boost) end
        for _ = 1, 1440 do b:update(1 / 144, boost) end
        equal(a.cursor, b.cursor); equal(a.score, b.score); equal(a.health, b.health)
        equal(table.concat(a.tracks), table.concat(b.tracks)); near(a.heat, b.heat, 0.3)
    end
end)
test("complete three-disk run with real timed inputs", function()
    local g = copying(191)
    local safety = 0
    while g.phase ~= "won" and g.phase ~= "lost" and safety < 2000 do
        safety = safety + 1
        if g.phase == "swap" then
            local time = g.time; g:update(20, false); equal(time, g.time); g:start()
        elseif #g:badTracks() > 0 then g:beginRepair(); perfect(g)
        else g:update(0.1, false) end
    end
    equal(g.phase, "won"); equal(g.disk, 3); equal(g.rescued, 24)
    equal(g.health, 5); equal(g.copied, 480); assert(g.time > 35); assert(g.score > 30000)
    local score = g.score; g:finish(true, "again"); equal(g.score, score)
    print(string.format("  Campaign: %d points, %.1fs left, %d perfects", g.score, g.time, g.perfects))
end)
print(string.format("\n%d passed / %d failed", passed, failed))
os.exit(failed == 0 and 0 or 1)
