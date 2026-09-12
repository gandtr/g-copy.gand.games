local Game = require("src.Game")
local Audio = require("src.Audio")
local Storage = require("src.Storage")
local UI = require("src.UI")
local Skin = require("src.Skin")
local Overlay = require("src.Overlay")
local game, audio, skin, settings, canvas
local page, clock, turboHeld = nil, 0, false
local sandbox = os.getenv("XCOPY_DEMO") or os.getenv("XCOPY_SMOKE")

local function newGame(start)
    game = Game.new(tonumber(os.getenv("XCOPY_SEED")) or os.time())
    page, turboHeld = nil, false
    if start then game:start() end
end

local function save()
    if sandbox then return end
    local ok, err = Storage.save(settings)
    if not ok then print("Could not save preferences: " .. tostring(err)) end
end

local function primary()
    if page then page = nil
    elseif game.paused then game:togglePause()
    elseif game.phase == "ready" or game.phase == "swap" then game:start()
    elseif game.phase == "won" or game.phase == "lost" then newGame(true)
    else game:hit() end
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.keyboard.setKeyRepeat(false)
    UI.init()
    canvas = love.graphics.newCanvas(UI.W, UI.H)
    settings, skin = Storage.load(), Skin.new()
    audio = Audio.new(settings)
    newGame(false)
    if os.getenv("XCOPY_DEMO") then require("src.Demo").setup(game, os.getenv("XCOPY_DEMO")) end
    if os.getenv("XCOPY_SMOKE") then require("tests.Smoke").run(game, audio) end
end

function love.update(dt)
    dt = math.min(dt, 0.1)
    clock = clock + dt
    if not page then
        local boost = turboHeld or love.keyboard.isDown("lshift", "rshift")
        game:update(dt, boost)
    end
    for _, event in ipairs(game:drainEvents()) do
        audio:event(event)
        if event.kind == "win" or event.kind == "lose" then
            settings.best = math.max(settings.best, game.score)
            save()
        end
    end
    audio:update(dt, game, page ~= nil)
end

function love.draw()
    local mx, my = UI.mouse(love.mouse.getPosition())
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0)
    skin:draw(game, settings, clock, mx, my)
    Overlay.draw(page, game, settings)
    love.graphics.setCanvas()
    love.graphics.clear(0.015, 0.025, 0.03)
    love.graphics.setColor(1, 1, 1)
    local scale, x, y = UI.transform()
    love.graphics.draw(canvas, x, y, 0, scale, scale)
end

function love.keypressed(key, _, repeated)
    if repeated then return end
    if key == "f11" then love.window.setFullscreen(not love.window.getFullscreen(), "desktop"); return end
    if key == "m" or key == "s" then
        local setting = key == "m" and "music" or "sfx"
        settings[setting] = not settings[setting]; save(); return
    end
    if key == "h" or key == "c" then
        local target = key == "h" and "help" or "credits"
        if page == target then page = nil else page = target end
        turboHeld = false
        return
    end
    if page then
        if key == "escape" or key == "return" or key == "space" then page = nil end
        return
    end
    if key == "return" or key == "space" then primary()
    elseif key == "r" and (game.phase == "won" or game.phase == "lost") then newGame(true)
    elseif key == "p" then game:togglePause()
    elseif key == "escape" then
        if not game:cancelRepair() then game:togglePause() end
    elseif key == "right" or key == "down" or key == "tab" then game:cycle(1)
    elseif key == "left" or key == "up" then game:cycle(-1) end
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end
    x, y = UI.mouse(x, y)
    if page then
        if page == "settings" and UI.contains(x, y, 177, 310, 186, 19) then love.keypressed("m")
        elseif page == "settings" and UI.contains(x, y, 385, 310, 186, 19) then love.keypressed("s")
        elseif UI.contains(x, y, 200, page == "settings" and 354 or 399, 356, 22) then page = nil end
        return
    end
    if game.phase ~= "copying" or game.paused then
        if UI.contains(x, y, 203, 354, 350, 20) or UI.contains(x, y, 77, 192, 86, 25) then primary(); return end
    end
    if UI.contains(x, y, 77, 192, 602, 25) then
        local buttonIndex = math.floor((x - 77) / 86) + 1
        if buttonIndex == 1 then
            if game.phase ~= "copying" or game.paused then primary() end
        elseif buttonIndex == 2 then primary()
        elseif buttonIndex == 3 then game:togglePause()
        elseif buttonIndex == 4 then page = "help"
        elseif buttonIndex == 5 then page = "credits"
        elseif buttonIndex == 6 then game:cycle(1)
        elseif buttonIndex == 7 then page = "settings" end
        return
    end
    if game.phase ~= "copying" or game.paused then return end
    if UI.contains(x, y, 561, 471, 131, 19) then turboHeld = true; return end
    if UI.contains(x, y, 550, 501, 142, 19) then game:hit(); return end
    local track = Skin.trackAt(x, y)
    if track then
        if game.repair and track == game.repair.index then game:hit()
        elseif not game.repair then game:beginRepair(track) end
    end
end

function love.mousereleased(_, _, button) if button == 1 then turboHeld = false end end
function love.focus(focused)
    if not focused then
        turboHeld = false
        if game and game.phase == "copying" and not sandbox then game.paused = true end
    end
end
function love.quit() if settings then save() end end
require("harness")
