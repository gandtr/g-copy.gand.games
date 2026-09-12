local UI = require("src.UI")
local Skin = {}
Skin.__index = Skin
local DISKS = {"DEMOSCENE VOL.01", "PIXEL ARCHIVE", "THE LAST BACKUP"}
local TOOLTIP = {
    "START / ENTER: SPIN UP OR RESUME", "REPEAT / SPACE: SELECT A FAULT, THEN TIME YOUR RETRY",
    "STOP / P: PAUSE THE SHIFT", "DISK INFO / H: HOW TO PLAY",
    "DIRECTORY / C: MUSIC AND ASSET CREDITS", "CHECK: SELECT THE NEXT BAD TRACK",
    "DEFAULT: AUDIO SETTINGS",
}

function Skin.new()
    local self = setmetatable({}, Skin)
    self.image = love.graphics.newImage("assets/visuals/xcopy-1992.png")
    self.image:setFilter("nearest", "nearest")
    self.onBulb = love.graphics.newQuad(82, 244, 32, 36, 720, 568)
    self.offBulb = love.graphics.newQuad(146, 244, 32, 36, 720, 568)
    return self
end

function Skin.trackPosition(index)
    local side = math.floor((index - 1) / 80)
    local n = (index - 1) % 80
    return 338 + side * 188 + n % 10 * 16, 254 + math.floor(n / 10) * 16
end

function Skin.trackAt(x, y)
    for i = 1, 160 do
        local tx, ty = Skin.trackPosition(i)
        if UI.contains(x, y, tx - 1, ty - 1, 16, 16) then return i end
    end
end

function Skin:tracks(game, clock, mx, my)
    for i, state in ipairs(game.tracks) do
        local x, y = Skin.trackPosition(i)
        if state == "good" or state == "fixed" then
            local color = state == "fixed" and "cyan" or "green"
            UI.rect(x + 2, y + 5, 3, 4, color)
            UI.rect(x + 5, y + 8, 3, 3, color)
            UI.rect(x + 8, y + 3, 3, 6, color)
            UI.rect(x + 11, y + 1, 2, 3, color)
        elseif state == "bad" then
            UI.rect(x + 1, y + 1, 13, 13, math.floor(clock * 3) % 2 == 0 and "red" or {0.65, 0.08, 0})
            UI.text("!", x + 3, y + 3, 8, "black")
        end
        if i == game.selected then UI.outline(x, y, 15, 15, "yellow") end
        if state == "bad" and UI.contains(mx, my, x, y, 16, 16) then UI.outline(x, y, 15, 15, "white") end
        if i == game.cursor + 1 and game.phase == "copying" and not game.repair then
            UI.outline(x + 1, y + 1, 13, 13, "white")
        end
    end
end

function Skin:draw(game, settings, clock, mx, my)
    UI.color("white"); love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.image)
    UI.text("TRACK RESCUE  /  ARCADE DISK RECOVERY", 0, 10, 8, "cyan", 720, "center")
    -- Original screen stays intact on disk; only changing fields are overlaid here.
    UI.rect(73, 154, 171, 27, "black")
    UI.text(game.turbo and "TURBOCOPY" or "DOSCOPY", 77, 159, 12, game.turbo and "red" or "yellow")
    UI.rect(592, 157, 81, 19, "black")
    UI.text("DISK " .. game.disk, 596, 160, 10, "yellow")
    UI.rect(68, 222, 250, 13, "black")
    UI.text("SOURCE  DF0:  " .. string.format("%02d", game.disk), 77, 225, 8, "cyan")
    UI.rect(338, 221, 348, 13, "black")
    UI.text("UPPER SIDE", 338, 225, 8, "cyan", 160, "center")
    UI.text("LOWER SIDE", 526, 225, 8, "cyan", 160, "center")
    for drive = 0, 3 do
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(self.image, drive == game.disk and self.onBulb or self.offBulb, 82 + drive * 64, 340)
    end
    self:tracks(game, clock, mx, my)
    UI.rect(342, 384, 151, 10, "black")
    UI.text(string.format("TRACKS:%03d/160", game.cursor), 343, 385, 7, "cyan")
    UI.rect(545, 383, 137, 11, "black")
    UI.text(string.format("TIME:%02d:%02d", math.floor(game.time / 60), math.floor(game.time) % 60), 548, 385, 8,
        game.time < 20 and "red" or "cyan")
    UI.rect(64, 407, 628, 19, "black")
    local message = game.message
    if game.stall > 0 then message = "DRIVE COOLING... " .. string.format("%.1fs", game.stall) end
    UI.text(message, 74, 413, 8, game.health < 2 and "red" or "green")
    self:console(game, settings, clock, mx, my)
end

function Skin:console(game, settings, clock, mx, my)
    UI.text(string.format("DISK %d/3", game.disk), 64, 449, 8, "white")
    UI.text(DISKS[game.disk], 156, 449, 8, "cyan")
    UI.text(string.format("SCORE %06d", game.score), 373, 449, 8, "yellow")
    UI.text("CHAIN X" .. game.combo, 570, 449, 8, "green")
    UI.rect(64, 466, 628, 1, "dim")
    UI.text("INTEGRITY", 64, 477, 7, "cyan")
    for i = 1, 5 do UI.rect(139 + i * 13, 475, 9, 10, i <= game.health and "green" or "dim") end
    UI.text("HEAT", 254, 477, 7, "cyan")
    UI.outline(293, 475, 104, 10, "dim")
    UI.rect(295, 477, game.heat, 6, game.heat > 75 and "red" or "yellow")
    UI.text("FAULTS " .. #game:badTracks(), 428, 477, 7, #game:badTracks() > 0 and "red" or "cyan")
    UI.button("HOLD: TURBO", 561, 471, 131, game.turbo or UI.contains(mx, my, 561, 471, 131, 19))
    if game.repair then
        local r = game.repair
        UI.text("RETRY " .. string.format("%02d", (r.index - 1) % 80), 64, 507, 8, "yellow")
        UI.rect(171, 499, 367, 25, "dark"); UI.outline(171, 499, 367, 25, "dim")
        UI.rect(174 + (r.center - r.width / 2) * 360, 502, r.width * 360, 19, "green")
        UI.rect(174 + (r.center - r.width * 0.18) * 360, 502, r.width * 0.36 * 360, 19, "white")
        local marker = 174 + game:marker() * 360
        UI.rect(marker - 2, 497, 4, 29, "yellow")
        UI.button("SPACE / RETRY", 550, 501, 142, UI.contains(mx, my, 550, 501, 142, 19))
    else
        UI.text("SPACE", 64, 504, 8, "yellow")
        UI.text("RETRY RED TRACK", 122, 504, 7, "cyan")
        UI.text("SHIFT", 293, 504, 8, "yellow")
        UI.text("TURBO", 353, 504, 7, "cyan")
        UI.text("H", 432, 504, 8, "yellow")
        UI.text("HELP", 452, 504, 7, "cyan")
        UI.text("P", 535, 504, 8, "yellow")
        UI.text("PAUSE", 555, 504, 7, "cyan")
        UI.text("M", 640, 504, 8, "yellow")
        UI.text(settings.music and "ON" or "OFF", 659, 504, 7, "cyan")
    end
    UI.rect(64, 534, 628, 1, "dim")
    local tip = "A500 DRIVE AUDIO  /  HOLIZNA - ADVENTURE BEGINS  /  CC0"
    if my >= 192 and my <= 217 and mx >= 77 and mx < 680 then
        tip = TOOLTIP[math.min(7, math.floor((mx - 77) / 86) + 1)]
    elseif game.repair then tip = "GREEN = RECOVER  /  WHITE = PERFECT  /  ESC = CANCEL"
    elseif #game:badTracks() > 0 then tip = "CLICK A RED ! OR PRESS SPACE. ARROWS CYCLE DAMAGED TRACKS." end
    UI.text(tip, 64, 547, 7, "dim")
end

return Skin
