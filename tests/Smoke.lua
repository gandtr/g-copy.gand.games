local Smoke={}
function Smoke.run(app,audio)
    local UI=require("src.UI")
    local function click(id,value)
        love.draw()
        local region
        for _,r in ipairs(UI.regions) do if r.id==id and (value==nil or r.value==value) then region=r; break end end
        assert(region,"missing clickable control "..id)
        local scale,ox,oy=UI.transform()
        love.mousepressed(ox+(region.x+region.w/2)*scale,oy+(region.y+region.h/2)*scale,1)
    end
    assert(audio.music:getDuration()>50)
    for i=1,4 do assert(audio.samples["click"..i]:getDuration()<0.1) end
    click("master","moon"); assert(app.page=="info")
    click("range"); click("edit","first"); love.textinput("12"); love.keypressed("return")
    assert(app.game.config.first==12)
    click("side"); assert(app.game.config.side=="UPPER")
    click("close"); click("defaults"); click("field","mode"); assert(app.game.config.mode=="DOSCOPY+")
    click("defaults"); click("start"); assert(app.game.phase=="reading")
    app.game:update(6,false); assert(app.game.phase=="swap")
    click("swap"); assert(app.game.phase=="writing"); assert(app.game.profile.blanks==2)
    for _=1,1000 do
        if app.game.phase=="complete" then break end
        if app.game.phase=="swap" then click("swap") else app.game:update(0.1,false) end
    end
    click("verify"); app.game:update(5,false); assert(app.game.verified)
    click("deliver"); assert(app.game.profile.money==100)
    click("repeat"); assert(app.game:busy())
    app.game:abort(); app.game.profile.money=500
    click("market"); click("market_tab","hardware"); click("upgrade","ram1024"); assert(app.game.profile.ram==1024)
    click("upgrade","drive2"); assert(app.game.profile.drives==2)
    click("close"); click("drive",1); assert(app.page=="drive")
    click("close"); click("tools"); click("info"); assert(app.page=="info")
    click("close"); click("music"); love.update(0.01); assert(audio.music:getVolume()==0)
    click("music"); click("sfx"); love.update(0.01); assert(not audio.motor:isPlaying()); click("sfx")
    app.game:defaults(); app.page=nil
    print("SMOKE PASS: native UI, typing ranges, profile fields, swaps, verification, payment, repeat, hardware, drives, tools, audio")
end
return Smoke
