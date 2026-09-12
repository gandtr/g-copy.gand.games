-- Deterministic visual fixtures. Never active during ordinary play or saved as scores.
local Demo = {}
function Demo.setup(game, mode)
    game:start()
    game:update(8, false)
    if mode == "retry" then
        game:beginRepair()
        game.repair.elapsed = game.repair.period * 0.35
    elseif mode == "win" then
        game.disk, game.score, game.rescued, game.perfects = 3, 27480, 24, 18
        game.time = 28
        for i = 1, 160 do game.tracks[i] = i % 11 == 0 and "fixed" or "good" end
        game.cursor = 160
        game:finish(true, "ALL THREE DISKS RESCUED")
    elseif mode == "loss" then game:finish(false, "SHIFT OVER. OUT OF TIME.") end
end
return Demo
