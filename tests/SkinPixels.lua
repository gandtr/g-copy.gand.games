local Test={}
function Test.run()
    local Game=require("src.Game"); local Skin=require("src.Skin"); local UI=require("src.UI")
    local g=Game.new(1); g.profile.drives=2; g.targets={[1]=1}
    local skin=Skin.new()
    local source=love.graphics.newImage("assets/visuals/g-copy-gand.png")
    source:setFilter("nearest","nearest")
    local iw,ih=source:getDimensions(); assert(iw==1402 and ih==1122)
    local sx,sy=640/1222,406/802
    local function pos(x,y) return 58+(x-90)*sx,30+(y-60)*sy end
    local function render(draw)
        local canvas=love.graphics.newCanvas(720,584,{dpiscale=1})
        love.graphics.push("all"); love.graphics.setCanvas(canvas); love.graphics.origin()
        love.graphics.setScissor(); love.graphics.clear(0,0,0); love.graphics.setColor(1,1,1)
        draw(); love.graphics.setCanvas(); love.graphics.pop()
        return canvas:newImageData()
    end
    local function background()
        love.graphics.draw(source,love.graphics.newQuad(90,60,1222,802,iw,ih),58,30,0,sx,sy)
    end
    local expected=render(background)
    local actual=render(function() UI.begin(-1,-1); skin:draw(g,{music=true,sfx=true},0) end)
    local function equal(a,b,x,y,label)
        local r,g,b1=a:getPixel(x,y); local r2,g2,b2=b:getPixel(x,y)
        assert(math.abs(r-r2)<1/255 and math.abs(g-g2)<1/255 and math.abs(b1-b2)<1/255,label.." at "..x..","..y)
    end
    local checked=0
    for y=0,567 do for x=0,719 do
        local live=(x>=64 and x<693 and y>=406 and y<428)
        for d=0,3 do for _,by in ipairs({480,680}) do
            local bx,dy=pos(128+d*118,by)
            if x>=math.floor(bx) and x<math.ceil(bx+56*sx) and y>=math.floor(dy) and y<math.ceil(dy+76*sy) then live=true end
        end end
        if not live then equal(expected,actual,x,y,"G-COPY artwork changed"); checked=checked+1 end
    end end
    for mode=0,2 do
        g.targets={[1]=mode}
        local result=render(function() skin:draw(g,{music=true,sfx=true},0) end)
        local x,y=pos(246,680)
        local reference=render(function()
            local qx=mode==1 and 128 or 245; local qy=mode==2 and 680 or 480
            love.graphics.draw(source,love.graphics.newQuad(qx,qy,56,76,iw,ih),x,y,0,sx,sy)
        end)
        for py=math.ceil(y),math.floor(y+76*sy)-1 do for px=math.ceil(x),math.floor(x+56*sx)-1 do
            equal(reference,result,px,py,"G-COPY target bulb mismatch")
        end end
    end
    print("PIXEL PASS: "..checked.." G-COPY artwork pixels and all three target bulb sprites match")
end
return Test
