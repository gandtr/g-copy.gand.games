local Smoke = {}
function Smoke.run(game, audio)
    assert(audio.music:getDuration() > 50)
    for name, source in pairs(audio.samples) do assert(source:getDuration() > 0, name) end
    for i = 1, 4 do assert(audio.samples["click" .. i]:getDuration() < 0.1, "short individual head click") end
    local UI = require("src.UI")
    local Skin = require("src.Skin")
    local function click(x, y)
        local scale, ox, oy = UI.transform()
        love.mousepressed(x * scale + ox, y * scale + oy, 1)
    end
    click(120, 205); assert(game.phase == "copying", "START mouse hitbox")
    game:update(3, false)
    local index = assert(game:badTracks()[1])
    local x, y = Skin.trackPosition(index)
    click(x + 5, y + 5); assert(game.repair, "track selection")
    love.keypressed("escape"); assert(not game.repair, "cancel retry")
    love.keypressed("space"); assert(game.repair, "keyboard select")
    game:update(game.repair.center * game.repair.period, false)
    click(590, 510); assert(game.rescued == 1, "RETRY mouse hitbox")
    love.keypressed("p"); assert(game.paused)
    love.keypressed("return"); assert(not game.paused)
    local before = game.time
    love.keypressed("h"); love.update(0.05); assert(game.time == before, "help freezes time")
    love.keypressed("h"); love.update(0.05); assert(game.time < before, "H closes help")
    love.keypressed("c"); before = game.time
    love.update(0.05); assert(game.time == before, "credits freezes time")
    love.keypressed("c"); love.update(0.05); assert(game.time < before, "C closes credits")
    click(575, 481); love.update(0.05); assert(game.turbo, "mouse turbo")
    love.mousereleased(0, 0, 1); love.update(0.05); assert(not game.turbo)
    love.keypressed("m"); love.update(0.05); assert(audio.music:getVolume() == 0)
    love.keypressed("m"); love.keypressed("s"); love.update(0.05); assert(not audio.motor:isPlaying())
    love.keypressed("s")
    print("SMOKE PASS: real assets, mouse/keyboard, retry, pause, help, credits, turbo, audio")
end
return Smoke
