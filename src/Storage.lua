local Storage = {}
function Storage.load()
    local settings = {best = 0, music = true, sfx = true}
    local data = love.filesystem.read("scores.dat")
    if data then
        settings.best = math.max(0, math.min(99999999, tonumber(data:match("best=(%d+)")) or 0))
        settings.music = data:match("music=(%d)") ~= "0"
        settings.sfx = data:match("sfx=(%d)") ~= "0"
    end
    return settings
end
function Storage.save(settings)
    return love.filesystem.write("scores.dat", string.format("best=%d\nmusic=%d\nsfx=%d\n",
        settings.best, settings.music and 1 or 0, settings.sfx and 1 or 0))
end
return Storage
