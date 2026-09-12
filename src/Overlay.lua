local UI = require("src.UI")
local Overlay = {}

local function frame(title, subtitle)
    UI.color("black", 0.65)
    love.graphics.rectangle("fill", 60, 219, 636, 181)
    UI.panel(117, 233, 522, 157)
    UI.text(title, 127, 249, 16, "yellow", 502, "center")
    UI.text(subtitle, 127, 278, 8, "cyan", 502, "center")
end

local function action(label)
    UI.button(label, 203, 354, 350, false)
end

function Overlay.draw(page, game, settings)
    if page == "help" then
        UI.panel(102, 218, 550, 211)
        UI.text("SAVE THE LAST THREE DISKS", 116, 233, 12, "yellow", 522, "center")
        local lines = {
            "1. START spins up. Green ticks are safe tracks.",
            "2. Click a red ! or press SPACE to select a fault.",
            "3. Press SPACE again when the marker is in GREEN.",
            "   The WHITE centre earns a perfect + combo bonus.",
            "4. Hold SHIFT for turbo. Release before heat fills!",
            "5. Fix every red track, then START the next disk.",
            "Five mistakes or zero time ends your 110s shift.",
        }
        for i, line in ipairs(lines) do UI.text(line, 117, 252 + i * 16, 7, i == 7 and "yellow" or "cyan") end
        UI.button("ENTER / H / ESC: BACK", 200, 399, 356, false)
    elseif page == "credits" then
        UI.panel(102, 220, 550, 209)
        UI.text("THE SOUND OF COPYING", 112, 236, 12, "yellow", 530, "center")
        UI.text("MUSIC: HOLIZNA - ADVENTURE BEGINS LOOP", 117, 270, 8, "white")
        UI.text("Happy Chiptunes collection / Public domain CC0", 117, 290, 7, "cyan")
        UI.text("MECHANICS: UAE A500 DRIVE SAMPLE SET", 117, 314, 8, "white")
        UI.text("Original sample files / upstream GPL-2.0", 117, 334, 7, "cyan")
        UI.text("X-COPY 1992 GRAPHICS: CPL / ORIGINAL AUTHORS", 117, 358, 7, "cyan")
        UI.text("Temporary original skin. Full sources in docs/ASSETS.md", 117, 377, 7, "dim")
        UI.button("ENTER / C / ESC: BACK", 200, 399, 356, false)
    elseif page == "settings" then
        frame("AUDIO SETUP", "M TO TOGGLE MUSIC / S TO TOGGLE DRIVE SOUNDS")
        UI.button("MUSIC: " .. (settings.music and "ON" or "OFF"), 177, 310, 186, false)
        UI.button("DRIVE SFX: " .. (settings.sfx and "ON" or "OFF"), 385, 310, 186, false)
        action("ENTER / ESC: BACK")
    elseif game.paused then
        frame("DRIVE STOPPED", "SHIFT PAUSED. YOUR DISKS ARE SAFE HERE.")
        UI.text("P / ESC resumes  -  H opens the manual", 129, 319, 8, "white", 498, "center")
        action("START / ENTER TO RESUME")
    elseif game.phase == "ready" then
        frame("TRACK RESCUE", "THREE DYING DISKS. ONE LAST CHANCE TO COPY.")
        UI.text("Catch red tracks. Time your retries. Keep it cool.", 129, 308, 8, "white", 498, "center")
        UI.text("SPACE: RETRY   SHIFT: TURBO   H: HOW TO PLAY", 129, 330, 7, "cyan", 498, "center")
        action("START / ENTER TO BEGIN")
    elseif game.phase == "swap" then
        frame("COPY VERIFIED!", "DISK " .. game.disk .. " RESCUED. LOAD THE NEXT FLOPPY.")
        UI.text("+" .. game.disk * 1000 .. " BONUS   /   " .. math.floor(game.time) .. " SECONDS LEFT", 129, 318, 8, "green", 498, "center")
        action("START / SPACE: INSERT NEXT DISK")
    elseif game.phase == "won" or game.phase == "lost" then
        frame(game.phase == "won" and "OPERATION COMPLETE!" or "READ FAILURE", game.message)
        UI.text(string.format("SCORE %06d    BEST %06d", game.score, settings.best), 129, 305, 10, "green", 498, "center")
        UI.text(game.rescued .. " SAVED  /  " .. game.perfects .. " PERFECT  /  " .. game.misses .. " MISTAKES", 129, 330, 7, "cyan", 498, "center")
        action("ENTER / R: COPY AGAIN")
    end
end
return Overlay
