local UI={W=720,H=584,regions={}}
UI.colors={black={0,0,0},cyan={0.35,0.78,0.82},dark={0.025,0.10,0.12},dim={0.23,0.4,0.42},
 white={0.9,0.97,0.96},green={0.05,1,0},yellow={1,0.9,0},red={1,0.22,0.12},purple={0.2,0,0.3}}
function UI.init()
    UI.fonts={}
    -- Rasterize type at three times design size, then draw into the native
    -- framebuffer. The whole interface is no longer a stretched 720px bitmap.
    for _,size in ipairs({6,7,8,9,10,11,12,14,16}) do
        UI.fonts[size]=love.graphics.newFont("assets/fonts/PressStart2P-Regular.ttf",size*3)
        UI.fonts[size]:setFilter("linear","linear")
    end
    UI.hand=love.mouse.getSystemCursor("hand"); UI.arrow=love.mouse.getSystemCursor("arrow")
end
function UI.color(color,alpha)
    local c=UI.colors[color] or color; love.graphics.setColor(c[1],c[2],c[3],alpha or 1)
end
function UI.rect(x,y,w,h,color) UI.color(color); love.graphics.rectangle("fill",x,y,w,h) end
function UI.outline(x,y,w,h,color)
    UI.rect(x,y,w,0.8,color); UI.rect(x,y+h-0.8,w,0.8,color)
    UI.rect(x,y,0.8,h,color); UI.rect(x+w-0.8,y,0.8,h,color)
end
function UI.text(text,x,y,size,color,width,align)
    UI.color(color or "cyan"); love.graphics.setFont(UI.fonts[size or 8])
    if width then love.graphics.printf(tostring(text),x,y,width*3,align or "left",0,1/3,1/3)
    else love.graphics.print(tostring(text),x,y,0,1/3,1/3) end
end
function UI.zero(x,y,color)
    -- X-Copy marks success with a small hollow 0, not a tick or slashed zero.
    local glyph={"01110","10001","10001","10001","10001","10001","01110"}
    for row,bits in ipairs(glyph) do
        for col=1,5 do if bits:sub(col,col)=="1" then
            UI.rect(x+(col-1)*1.5,y+(row-1)*1.5,1.5,1.5,color)
        end end
    end
end
function UI.panel(x,y,w,h)
    UI.rect(x+4,y+4,w,h,"black"); UI.rect(x,y,w,h,"black")
    UI.outline(x,y,w,h,"cyan"); UI.outline(x+2,y+2,w-4,h-4,"dim")
end
function UI.contains(x,y,bx,by,bw,bh) return x>=bx and x<bx+bw and y>=by and y<by+bh end
function UI.begin(mx,my) UI.regions={}; UI.mx,UI.my=mx,my; UI.tip=nil end
function UI.hot(id,x,y,w,h,value,tip)
    local region={id=id,x=x,y=y,w=w,h=h,value=value,tip=tip}
    UI.regions[#UI.regions+1]=region
    local hover=UI.contains(UI.mx or -1,UI.my or -1,x,y,w,h)
    if hover then UI.tip=tip end
    return hover
end
function UI.button(label,x,y,w,id,value,tip,selected)
    local hover=UI.hot(id,x,y,w,20,value,tip or label)
    UI.rect(x,y,w,20,(hover or selected) and "cyan" or "dark")
    UI.outline(x,y,w,20,"cyan")
    UI.rect(x+1,y+1,w-2,1,"white"); UI.rect(x+1,y+1,1,17,"white")
    UI.rect(x+2,y+18,w-3,1,"dim")
    UI.text(label,x,y+6,7,(hover or selected) and "black" or "yellow",w,"center")
end
function UI.hit(x,y)
    for i=#UI.regions,1,-1 do local r=UI.regions[i]
        if UI.contains(x,y,r.x,r.y,r.w,r.h) then return r end
    end
end
function UI.transform()
    local w,h=love.graphics.getDimensions(); local scale=math.min(w/UI.W,h/UI.H)
    -- Snap to whole physical pixels on Retina as well as standard displays.
    local dpi=love.window.getDPIScale()
    if scale*dpi>=1 then scale=math.floor(scale*dpi)/dpi end
    return scale,math.floor((w-UI.W*scale)/2),math.floor((h-UI.H*scale)/2)
end
function UI.mouse(x,y) local s,ox,oy=UI.transform(); return (x-ox)/s,(y-oy)/s end
return UI
