local App=require("src.App")
local Audio=require("src.Audio")
local Storage=require("src.Storage")
local UI=require("src.UI")
local Skin=require("src.Skin")
local Overlay=require("src.Overlay")
local app,audio,skin,clock
local sandbox=os.getenv("XCOPY_DEMO") or os.getenv("XCOPY_SMOKE")
local function save()
    if sandbox or not app then return end
    local ok,err=Storage.save(app.settings,app.game.profile)
    if not ok then print("Save failed: "..tostring(err)) end
end
function love.load()
    love.graphics.setDefaultFilter("nearest","nearest")
    love.keyboard.setKeyRepeat(true)
    UI.init()
    local settings,profile
    if sandbox then settings,profile=Storage.defaults() else settings,profile=Storage.load() end
    app=App.new(settings,profile,tonumber(os.getenv("XCOPY_SEED")) or os.time())
    audio,skin,clock=Audio.new(settings),Skin.new(),0
    if os.getenv("XCOPY_DEMO") then require("src.Demo").setup(app,os.getenv("XCOPY_DEMO")) end
    if os.getenv("XCOPY_SMOKE") then require("tests.Smoke").run(app,audio) end
end
function love.update(dt)
    dt=math.min(dt,0.1); clock=clock+dt
    if not app.page then app.game:update(dt,app.turboHeld or love.keyboard.isDown("lshift","rshift")) end
    for _,event in ipairs(app.game:drainEvents()) do
        audio:event(event); if event.kind=="save" then save() end
    end
    audio:update(dt,app.game,app.page~=nil)
end
function love.draw()
    local mx,my=UI.mouse(love.mouse.getPosition())
    UI.begin(mx,my)
    love.graphics.clear(0,0,0)
    local scale,x,y=UI.transform()
    love.graphics.push(); love.graphics.translate(x,y); love.graphics.scale(scale)
    UI.rect(0,0,UI.W,UI.H,"black")
    skin:draw(app.game,app.settings,clock)
    Overlay.draw(app)
    if app.page then UI.text(app.game.message,64,561,7,"cyan",628) end
    love.graphics.pop()
    love.mouse.setCursor(UI.hit(mx,my) and UI.hand or UI.arrow)
end
function love.keypressed(key,_,repeated)
    if key=="f11" and not repeated then love.window.setFullscreen(not love.window.getFullscreen(),"desktop"); return end
    if repeated and not app.editKey then return end
    app:key(key)
end
function love.textinput(text)
    if app.editKey then app.editText=(app.editText..text:gsub("%D","")):sub(1,2) end
end
function love.mousepressed(x,y,button)
    if button~=1 and button~=2 then return end
    x,y=UI.mouse(x,y)
    local region=UI.hit(x,y)
    if region then
        if button==2 and region.id=="field" and (region.value=="first" or region.value=="last") then
            app:action("adjust",{key=region.value,delta=-1})
        else app:action(region.id,region.value,y) end
    end
end
function love.mousereleased(_,_,button) if button==1 then app.turboHeld=false end end
function love.focus(focused)
    if not focused and app then
        app.turboHeld=false
        if app.game:busy() and not sandbox then app.game.paused=true end
    end
end
function love.quit() save() end
require("harness")
