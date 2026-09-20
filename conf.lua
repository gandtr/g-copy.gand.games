function love.conf(t)
    t.identity = "g-copy"
    -- 11.4 is the oldest supported API and the bundled love.js runtime.
    t.version = "11.4"
    t.window.title = "G Copy"
    t.window.width, t.window.height = 1080, 900
    t.window.minwidth, t.window.minheight = 1, 1
    t.window.resizable = true
    t.window.vsync = 1
    t.window.highdpi = true
    t.modules.physics, t.modules.joystick = false, false
end
