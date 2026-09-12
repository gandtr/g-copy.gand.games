local Audio = {}
Audio.__index = Audio
local function gain(db) return 10 ^ (db / 20) end

function Audio.new(settings)
    local self = setmetatable({settings = settings, voices = {}, mediaQueue={}, musicDb = -14}, Audio)
    self.samples = {}
    for _, name in ipairs({"snatch", "spin", "startup"}) do
        self.samples[name] = love.audio.newSource("assets/audio/drive_" .. name .. ".wav", "static")
    end
    for i = 1, 4 do
        self.samples["click" .. i] = love.audio.newSource("assets/audio/head_click_" .. i .. ".wav", "static")
    end
    for _,name in ipairs({"insert","eject"}) do
        self.samples[name]=love.audio.newSource("assets/audio/floppy_"..name..".ogg","static")
    end
    self.motor = self.samples.spin:clone()
    self.motor:setLooping(true)
    self.music = love.audio.newSource("assets/audio/adventure-begins.ogg", "stream")
    self.music:setLooping(true)
    self.music:setVolume(0)
    self.music:play()
    self.clickDelay = 0
    return self
end

function Audio:play(name, db, pitch)
    if not self.settings.sfx or #self.voices >= 8 then return end
    if name == "click" then name = "click" .. love.math.random(1, 4) end
    local voice = self.samples[name]:clone()
    voice:setVolume(gain(db or -7))
    voice:setPitch(pitch or 1)
    voice:play()
    self.voices[#self.voices + 1] = voice
end

function Audio:event(event)
    local kind = event.kind
    if kind=="media" then
        if not self.settings.sfx then return end
        local change=event.value
        if change.previous and change.previous~="empty" then self.mediaQueue[#self.mediaQueue+1]="eject" end
        if change.media~="empty" then self.mediaQueue[#self.mediaQueue+1]="insert" end
    elseif kind == "startup" then self:play("startup", -7)
    elseif kind == "track" and self.clickDelay <= 0 then
        self:play("click", -10, 0.97 + love.math.random() * 0.06)
        self.clickDelay = 0.06
    elseif kind == "seek" or kind == "fault" then self:play("snatch", -9)
    elseif kind == "repair" or kind == "perfect" then self:play("click", -4, 1.08)
    elseif kind == "disk" or kind == "win" then self:play("snatch", -4, 1.0)
    elseif kind == "miss" or kind == "lose" then self:play("snatch", -4, 0.8) end
end

function Audio:update(dt, game, covered)
    self.clickDelay = math.max(0, self.clickDelay - dt)
    for i = #self.voices, 1, -1 do
        if not self.voices[i]:isPlaying() then table.remove(self.voices, i) end
    end
    if self.mediaVoice and not self.mediaVoice:isPlaying() then self.mediaVoice=nil end
    if not self.settings.sfx then
        self.mediaQueue={}
        if self.mediaVoice then self.mediaVoice:stop(); self.mediaVoice=nil end
    elseif not self.mediaVoice and #self.mediaQueue>0 then
        self.mediaVoice=self.samples[table.remove(self.mediaQueue,1)]:clone()
        self.mediaVoice:setVolume(gain(-3)); self.mediaVoice:play()
    end
    local active = game:busy() and not game.paused and not covered
    local spinning = active and (game.phase == "reading" or game.phase == "writing" or game.phase == "copying" or game.phase == "verifying") and game.stall <= 0 and not game.repair
    if spinning and self.settings.sfx and not self.mediaVoice then
        if not self.motor:isPlaying() then self.motor:play() end
        self.motor:setVolume(gain(game.turbo and -13 or -18))
        self.motor:setPitch(game.turbo and 1.09 or 1)
    else self.motor:stop() end
    local target = self.mediaVoice and -21 or (active and (game.repair and -15 or -9) or -14)
    self.musicDb = self.musicDb + (target - self.musicDb) * math.min(1, dt * 6)
    self.music:setVolume(self.settings.music and gain(self.musicDb) or 0)
    if not self.settings.sfx then
        for _, voice in ipairs(self.voices) do voice:stop() end
    end
end

return Audio
