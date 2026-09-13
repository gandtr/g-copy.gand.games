function love.conf(t)
    t.identity = "g-copy"
    t.version = "11.5"
    t.window.title = "G Copy"
    t.window.width, t.window.height = 1080, 900
    t.window.minwidth, t.window.minheight = 720, 600
    t.window.resizable = true
    t.window.vsync = 1
    t.window.highdpi = true
    t.modules.physics, t.modules.joystick = false, false
end
