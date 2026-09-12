local Smoke={}
function Smoke.run(app,audio)
    local UI=require("src.UI")
    local function click(id,value)
        love.draw()
        local region
        for _,r in ipairs(UI.regions) do if r.id==id and (value==nil or r.value==value or (type(value)=="table" and type(r.value)=="table" and r.value.index==value.index and r.value.role==value.role and r.value.media==value.media)) then region=r; break end end
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
    click("tools"); click("market"); click("market_tab","hardware"); click("upgrade","ram1024"); assert(app.game.profile.ram==1024)
    click("upgrade","drive2"); assert(app.game.profile.drives==2)
    click("close"); click("drive",1); assert(app.page=="drive")
    click("close"); click("tools"); click("info"); assert(app.page=="info")
    click("close"); click("tools"); click("music"); love.update(0.01); assert(audio.music:getVolume()==0)
    click("music"); click("sfx"); love.update(0.01); assert(not audio.motor:isPlaying()); click("sfx")
    click("close")
    -- A fresh, isolated two-destination fixture, driven through real bulb hits.
    app.game=require("src.Game").new(31); local g=app.game
    g:buyMaster("moon"); g.profile.drives=3; app.page=nil
    for d=1,2 do
        click("drive_role",{index=d,role="target"}); assert(g.targets[d]==1)
        click("drive_role",{index=d,role="target"}); assert(g.targets[d]==2)
    end
    click("start"); assert(g.swapDrive==1); click("swap"); assert(g.swapDrive==2); click("swap")
    for _=1,200 do if g.phase=="complete" then break end; g:update(0.1,false) end
    assert(g.verified and g.copies[1].verified and g.copies[2].verified)
    click("deliver"); assert(g.profile.money==170 and g.profile.blanks==1)
    click("tools"); click("market"); assert(app.page=="market"); click("close")
    -- The real A600 samples play in order and the mute switch cancels the queue.
    assert(audio.samples.eject:getDuration()>0.5); assert(audio.samples.insert:getDuration()>0.4)
    audio.settings.sfx=true; audio.mediaQueue={}; audio.mediaVoice=nil
    audio:event({kind="media",value={previous="source",media="blank"}})
    assert(audio.mediaQueue[1]=="eject" and audio.mediaQueue[2]=="insert")
    audio:update(0.01,g,false); assert(audio.mediaVoice and #audio.mediaQueue==1)
    audio.mediaVoice:stop(); audio:update(0.01,g,false); assert(audio.mediaVoice and #audio.mediaQueue==0)
    audio.settings.sfx=false; audio:update(0.01,g,false); assert(not audio.mediaVoice and #audio.mediaQueue==0)
    audio.settings.sfx=true
    require("tests.SkinPixels").run()
    app.page=nil
    print("SMOKE PASS: native UI, typing ranges, profile fields, swaps, verification, payment, repeat, hardware, multiple COPY/V bulbs, automatic batch verification, payment, A600 media audio, original screen pixels")
end
return Smoke
