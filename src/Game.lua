local Game = {}
Game.__index = Game
local STEP, TRACKS = 1 / 120, 160

function Game.new(seed)
    local self = setmetatable({}, Game)
    self.seed = seed or os.time()
    self.rng = self.seed % 2147483647
    if self.rng == 0 then self.rng = 1 end
    self.phase, self.paused = "ready", false
    self.disk, self.score, self.combo = 1, 0, 0
    self.time, self.health, self.heat = 110, 5, 0
    self.rescued, self.perfects, self.misses, self.copied = 0, 0, 0, 0
    self.events, self.accumulator = {}, 0
    self:prepareDisk()
    return self
end

function Game:random()
    self.rng = (self.rng * 16807) % 2147483647
    return self.rng / 2147483647
end

function Game:emit(kind, value)
    self.events[#self.events + 1] = {kind = kind, value = value}
end

function Game:drainEvents()
    local events = self.events
    self.events = {}
    return events
end

function Game:prepareDisk()
    self.tracks, self.damage = {}, {}
    self.cursor, self.copyClock, self.stall = 0, 0, 0
    self.selected, self.repair = nil, nil
    self.heat, self.turbo = 0, false
    for i = 1, TRACKS do self.tracks[i] = "empty" end
    -- Stratified faults ensure an early teachable error without impossible clusters.
    local count = 4 + self.disk * 2
    for i = 1, count do
        local index = math.floor((i - 1) * TRACKS / count + 6 + self:random() * 10)
        self.damage[math.min(TRACKS, index)] = true
    end
    self.message = "PRESS START TO SPIN UP THE DRIVE"
end

function Game:start()
    if self.phase == "ready" then
        self.phase = "copying"
    elseif self.phase == "swap" then
        self.disk = self.disk + 1
        self:prepareDisk()
        self.phase = "copying"
    else
        return false
    end
    self.message = "COPYING... RESCUE RED TRACKS WITH SPACE"
    self:emit("startup")
    return true
end

function Game:badTracks()
    local bad = {}
    for i, state in ipairs(self.tracks) do
        if state == "bad" then bad[#bad + 1] = i end
    end
    return bad
end

function Game:cycle(direction)
    if self.repair or self.paused then return end
    local bad = self:badTracks()
    if #bad == 0 then return end
    local current = direction > 0 and 0 or 1
    for i, index in ipairs(bad) do
        if index == self.selected then current = i end
    end
    self.selected = bad[(current - 1 + direction) % #bad + 1]
end

function Game:beginRepair(index)
    if self.phase ~= "copying" or self.paused or self.stall > 0 or self.repair then return false end
    index = index or self.selected or self:badTracks()[1]
    if not index or self.tracks[index] ~= "bad" then return false end
    self.selected = index
    self.repair = {index = index, elapsed = 0,
        center = 0.32 + self:random() * 0.36,
        width = 0.29 - self.disk * 0.025,
        period = 1.9 - self.disk * 0.12}
    self.message = "PRESS SPACE WHEN THE MARKER IS IN GREEN"
    self:emit("seek")
    return true
end

function Game:marker()
    if not self.repair then return 0 end
    local phase = (self.repair.elapsed / self.repair.period) % 2
    return phase <= 1 and phase or 2 - phase
end

function Game:damageIntegrity(reason)
    self.health, self.combo, self.misses = self.health - 1, 0, self.misses + 1
    self.message = reason
    self:emit("miss")
    if self.health <= 0 then self:finish(false, "DISK INTEGRITY LOST") end
end

function Game:hit()
    if self.paused or self.phase ~= "copying" then return end
    if not self.repair then self:beginRepair(); return end
    local repair = self.repair
    local distance = math.abs(self:marker() - repair.center)
    self.repair = nil
    if distance <= repair.width / 2 then
        local perfect = distance <= repair.width * 0.18
        self.tracks[repair.index] = "fixed"
        self.rescued, self.combo = self.rescued + 1, math.min(8, self.combo + 1)
        local points = (perfect and 150 or 80) * self.combo
        self.score = self.score + points
        if perfect then self.perfects = self.perfects + 1 end
        self.message = (perfect and "PERFECT! " or "RECOVERED! ") .. "+" .. points .. "  CHAIN X" .. self.combo
        self:emit(perfect and "perfect" or "repair", points)
        self.selected = self:badTracks()[1]
        self:checkDisk()
    else
        self:damageIntegrity("READ ERROR! -1 INTEGRITY. TRY AGAIN.")
    end
end

function Game:cancelRepair()
    if self.repair then
        self.repair = nil
        self.message = "RETRY CANCELLED. COPYING RESUMED."
        return true
    end
    return false
end

function Game:togglePause()
    if self.phase == "copying" then
        self.paused = not self.paused
        self.turbo = false
    end
end

function Game:checkDisk()
    if self.cursor < TRACKS or #self:badTracks() > 0 then return end
    self.score = self.score + 1000 * self.disk
    self.repair, self.turbo = nil, false
    if self.disk == 3 then
        self:finish(true, "ALL THREE DISKS RESCUED")
    else
        self.phase = "swap"
        self.message = "COPY VERIFIED. INSERT THE NEXT DISK."
        self:emit("disk")
    end
end

function Game:finish(won, reason)
    if self.phase == "won" or self.phase == "lost" then return end
    self.phase, self.message = won and "won" or "lost", reason
    self.repair, self.turbo = nil, false
    if won then self.score = self.score + math.floor(self.time) * 25 + self.health * 250 end
    self:emit(won and "win" or "lose")
end

function Game:step(dt, turbo)
    self.time = math.max(0, self.time - dt)
    if self.time <= 0 then self:finish(false, "SHIFT OVER. OUT OF TIME."); return end
    self.turbo = turbo and not self.repair and self.stall <= 0 and self.cursor < TRACKS
    self.heat = math.max(0, self.heat + (self.turbo and 26 or -20) * dt)
    if self.heat >= 100 then
        self.heat, self.stall, self.turbo = 100, 2, false
        self:damageIntegrity("DRIVE OVERHEATED! RELEASE TURBO TO COOL.")
        if self.phase ~= "copying" then return end
    end
    if self.stall > 0 then self.stall = math.max(0, self.stall - dt); return end
    if self.repair then self.repair.elapsed = self.repair.elapsed + dt; return end
    self.copyClock = self.copyClock + dt * (self.turbo and 26 or 12)
    while self.copyClock >= 1 and self.cursor < TRACKS do
        self.copyClock, self.cursor = self.copyClock - 1, self.cursor + 1
        local bad = self.damage[self.cursor] or (self.turbo and self:random() < 0.035)
        self.tracks[self.cursor] = bad and "bad" or "good"
        self.copied = self.copied + 1
        if bad then
            self.selected = self.selected or self.cursor
            self.message = "BAD TRACK! CLICK RED OR PRESS SPACE TO RETRY"
            self:emit("fault")
        else
            self.score = self.score + (self.turbo and 15 or 10)
            self:emit("track")
        end
    end
    if self.cursor == TRACKS then self.copyClock = 0; self:checkDisk() end
end

function Game:update(dt, turbo)
    if self.phase ~= "copying" or self.paused then return end
    -- Fixed simulation ticks make heat, scoring, and seeded damage independent of FPS.
    self.accumulator = self.accumulator + dt
    while self.accumulator >= STEP do
        self.accumulator = self.accumulator - STEP
        self:step(STEP, turbo)
        if self.phase ~= "copying" then self.accumulator = 0; break end
    end
end

return Game
