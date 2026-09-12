local Test={}
function Test.run()
    local Game=require("src.Game"); local Skin=require("src.Skin"); local UI=require("src.UI")
    local g=Game.new(1); g.profile.drives=2; g.targets={[1]=1}
    local skin=Skin.new(); local canvas=love.graphics.newCanvas(720,584,{dpiscale=1})
    love.graphics.push("all"); love.graphics.setCanvas(canvas); love.graphics.origin(); love.graphics.clear(0,0,0)
    UI.begin(-1,-1); skin:draw(g,{music=true,sfx=true},0)
    love.graphics.setCanvas(); love.graphics.pop()
    local expected=love.image.newImageData("assets/visuals/xcopy-1992.png"); local actual=canvas:newImageData()
    local checked=0
    for y=0,567 do for x=0,719 do
        -- These rectangles represent live game state. Everything else must be
        -- pixel-identical: logo, labels, bevels, arrows, icons, grids, margins.
        local live=(x>=64 and x<693 and y>=406 and y<428)
        for d=0,3 do
            if x>=82+d*64 and x<114+d*64 and ((y>=244 and y<280) or (y>=340 and y<376)) then live=true end
        end
        if not live then
            local r,g,b=expected:getPixel(x,y); local a,c,d=actual:getPixel(x,y)
            assert(math.abs(r-a)<1/255 and math.abs(g-c)<1/255 and math.abs(b-d)<1/255,"original artwork changed at "..x..","..y)
            checked=checked+1
        end
    end end
    -- Check the exact original three bulb sprites, including the orange V.
    for mode=0,2 do
        g.targets={[1]=mode}
        love.graphics.push("all"); love.graphics.setCanvas(canvas); love.graphics.origin()
        skin:draw(g,{music=true,sfx=true},0); love.graphics.setCanvas(); love.graphics.pop()
        local result=canvas:newImageData()
        local sx=mode==1 and 82 or 146; local sy=mode==2 and 340 or 244
        for y=0,35 do for x=0,31 do
            local r,g,b=expected:getPixel(sx+x,sy+y); local a,c,d=result:getPixel(146+x,340+y)
            assert(math.abs(r-a)<1/255 and math.abs(g-c)<1/255 and math.abs(b-d)<1/255,"target bulb sprite mismatch")
        end end
    end
    print("PIXEL PASS: "..checked.." original screen pixels and all three target bulb sprites match")
end
return Test
