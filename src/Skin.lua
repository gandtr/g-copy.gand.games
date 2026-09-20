-- User-supplied G-COPY artwork, mapped into the existing logical desk.
-- Only live values, bulb states and track results are painted over its pixels.
local UI=require("src.UI")
local Skin={}; Skin.__index=Skin
-- The supplied image is 1402x1122 with a 1222x802 visible desk. Keep the
-- source intact and map its artwork into the responsive 640x406 viewport.
local SX,SY=640/1222,406/802
function Skin.position(x,y) return 58+(x-90)*SX,30+(y-60)*SY end
local function region(x,y,w,h)
    local dx,dy=Skin.position(x,y); return dx,dy,w*SX,h*SY
end
-- Additional live values use the same 7x6, two-pixel stroke geometry as the
-- original settings font. The source bitmap remains the default glyph source.
local EXTRA={
 N={"1100011","1110011","1111011","1101111","1100111","1100011"},
 L={"1100000","1100000","1100000","1100000","1100000","1111111"},
 A={"0111110","1100011","1100011","1111111","1100011","1100011"},
 M={"1100011","1110111","1111111","1101011","1100011","1100011"},
 R={"1111110","1100011","1111110","1101100","1100110","1100011"},
 U={"1100011","1100011","1100011","1100011","1100011","0111110"},
 T={"1111111","0011000","0011000","0011000","0011000","0011000"},
 ["+"]={"0000000","0011000","0011000","1111110","0011000","0011000"},
 ["2"]={"0111110","1100011","0000110","0011100","0110000","1111111"},
 ["3"]={"1111110","0000011","0011110","0000011","0000011","1111110"},
 ["5"]={"1111111","1100000","1111110","0000011","1100011","0111110"},
 ["6"]={"0111110","1100000","1111110","1100011","1100011","0111110"},
}
local BUTTONS={
 {"start","Start / resume copying"},{"repeat","NOCHMAL: retry or repeat"},
 {"pause","STOP: pause the drive"},{"info","Customer order and disk information"},
 {"directory","INHALT: your master collection"},{"verify","PRUEFEN: verify target disks"},
 {"defaults","ZURUECK: restore standard parameters"},
}
function Skin.new()
    local self=setmetatable({},Skin)
    self.image=love.graphics.newImage("assets/visuals/g-copy-gand.png")
    self.image:setFilter("nearest","nearest")
    local iw,ih=self.image:getDimensions()
    local function quad(x,y,w,h) return love.graphics.newQuad(x,y,w,h,iw,ih) end
    self.background=quad(90,60,1222,802)
    -- The reference's orange destination bulb already contains the original V.
    self.bulbs={off=quad(245,480,56,76),source=quad(128,480,56,76),copy=quad(128,480,56,76),verify=quad(245,680,56,76)}
    self.glyphs={}
    -- Sample the actual yellow type in the original settings, including its
    -- characteristic wide pixels. Unknown characters use the dialog font.
    local function glyphs(text,x,y)
        for i=1,#text do self.glyphs[text:sub(i,i)]=quad(x+(i-1)*31,y,31,28) end
    end
    glyphs("DOSCOPY",114,311); glyphs("BEIDE",769,311)
    glyphs("4489",954,311); glyphs("0",445,311); glyphs("1",710,311)
    glyphs("7",616,311); glyphs("DISK",1117,311)
    return self
end
function Skin:originalText(text,x,y)
    for i=1,#text do
        local c=text:sub(i,i); local quad=self.glyphs[c]
        if quad then love.graphics.setColor(1,1,1); love.graphics.draw(self.image,quad,x+(i-1)*16,y,0,16/31,14/28)
        elseif EXTRA[c] then
            for row,bits in ipairs(EXTRA[c]) do for col=1,7 do if bits:sub(col,col)=="1" then
                UI.rect(x+(i-1)*16+(col-1)*2,y+1+(row-1)*2,2,2,{1,0.8,0})
            end end end
        elseif c~=" " then UI.text(c,x+(i-1)*16,y+1,12,"yellow") end
    end
end
function Skin.trackPosition(index)
    local side=math.floor((index-1)/80); local n=(index-1)%80
    return Skin.position((side==0 and 604 or 969)+n%10*31.2,500+math.floor(n/10)*31.75)
end
function Skin:field(value,original,sourceX,sourceWidth,key)
    local x,y,w,h=region(sourceX,282,sourceWidth,89)
    UI.hot("field",x,y,w,h,key,"Change "..key:upper().."; click arrows or type track numbers")
    if value~=original then
        local tx,ty,tw,th=region(sourceX,307,sourceWidth,37)
        UI.rect(tx,ty,tw,th,"black")
        self:originalText(tostring(value),tx,ty+2)
    end
end
function Skin:drive(game,index)
    local sourceX=128+index*118; local owned=index<game.profile.drives
    for _,entry in ipairs({{y=480,role="source"},{y=680,role="target"}}) do
        local x,y,w,h=region(sourceX,entry.y,56,76)
        UI.rect(x,y,w,h,"black")
        UI.hot("drive_role",x,y,w,h,{role=entry.role,index=index},
            owned and (entry.role=="source" and "DF"..index..": select SOURCE" or "DF"..index..": OFF > COPY > V (auto verify) > OFF")
            or "DF"..index..": buy this external drive at MARKET")
        if owned then
            local mode=game.targets[index] or 0
            local state=entry.role=="source" and (game.source==index and "source" or "off") or (mode==2 and "verify" or mode==1 and "copy" or "off")
            love.graphics.setColor(1,1,1); love.graphics.draw(self.image,self.bulbs[state],x,y,0,SX,SY)
        end
    end
    local x,y,w,h=region(110+index*118,564,94,106)
    UI.hot("drive",x,y,w,h,index,owned and "DF"..index..": insert or eject disk / inspect target" or "Buy external DF"..index..":")
end
function Skin:tracks(game)
    for i,state in ipairs(game.tracks) do
        local x,y=Skin.trackPosition(i)
        if state=="good" then UI.zero(x+4,y+2,"green")
        elseif state=="buffer" then UI.zero(x+4,y+2,"yellow")
        elseif tonumber(state) then UI.text(state,x+2,y+2,11,"red")
        elseif state=="skip" then UI.rect(x+6,y+7,2,2,"dim") end
        UI.hot("track",x,y,15,15,i,"Track "..string.format("%02d",(i-1)%80)..(i<=80 and " upper" or " lower")..": "..state)
        if i==game.selected and game.phase=="blocked" then UI.outline(x,y,15,15,"yellow")
        elseif i==game.cursor and game:busy() then UI.outline(x,y,15,15,"cyan") end
    end
end
function Skin:draw(game,settings,clock)
    love.graphics.setColor(1,1,1); love.graphics.draw(self.image,self.background,58,30,0,SX,SY)
    UI.hot("credits",64,32,628,86,nil,"G-COPY by Gand: artwork and audio credits")
    UI.hot("mode",74,121,69,20,nil,"COPY: cycle DOSCOPY / DOSCOPY+ / NIBBLE")
    UI.hot("tools",147,121,79,20,nil,"TOOLS: market, hardware, settings, audio, help")
    self:field(game.config.mode,"DOSCOPY",114,300,"mode")
    self:field(string.format("%02d",game.config.first),"00",445,64,"first")
    self:field(string.format("%02d",game.config.last),"79",616,64,"last")
    self:field(({BOTH="BEIDE",UPPER="OBEN",LOWER="UNTEN"})[game.config.side],"BEIDE",769,160,"side")
    self:field(game.config.sync,"4489",954,128,"sync")
    self:field(game.config.device,"DISK",1117,136,"device")
    UI.hot("range",249,121,151,21,nil,"Set exact track range and track length")
    UI.hot("range",301,143,22,44,nil,"Track range, side and long-track options")
    UI.hot("range",389,143,22,44,nil,"Track range, side and long-track options")
    UI.hot("side",417,121,78,21,nil,"SEITE: BOTH / UPPER / LOWER")
    UI.hot("sync",510,121,74,21,nil,"Change sync word")
    UI.hot("device",596,121,86,21,nil,"UEBER: DISK / RAM buffer route")
    for i,b in ipairs(BUTTONS) do
        local x,y,w,h=region(114+(i-1)*165,382,158,45)
        UI.hot(b[1],x,y,w,h,nil,b[2])
    end
    for i=0,3 do self:drive(game,i) end
    self:tracks(game)
    if game.time>=1 then
        local tx,ty,tw,th=region(1142,760,116,28)
        UI.rect(tx,ty,tw,th,"black")
        UI.text(string.format("%02d:%02d",math.floor(game.time/60),math.floor(game.time)%60),tx+1,ty+2,8,"cyan")
    end
    -- The original status frame remains intact. Full messages are one click
    -- away, leaving space for the original large lettering and black margins.
    UI.rect(64,406,629,22,"black")
    local status
    if game.phase=="idle" then status="Freier Speicher: "..((game.profile.ram-64)*1024).." Bytes."
    elseif game.phase=="complete" and game.verified then status="VERIFIED  $"..game:payout().."  > DELIVER"
    elseif game.phase=="delivered" then status="PAID $"..game:payout().."  > MARKET"
    elseif game.phase=="blocked" then status=game.repair and "ALIGN READ HEAD  > SPACE" or "READ ERROR  > NOCHMAL / INFO"
    elseif game.phase=="verifying" then status="VERIFYING "..#game.verifyingTargets.." TARGET(S)..."
    else status=game.phase:upper().."  "..#game.batch.." TARGET(S)  /  "..#game.buffer.." BUFFERED" end
    UI.text(status,74,411,11,game.phase=="blocked" and "red" or "green")
    UI.hot(game.phase=="complete" and game.verified and "deliver" or game.phase=="delivered" and "market" or "status",60,402,637,31,nil,game.message)
    if game.repair then
        local r=game.repair
        UI.rect(74,441,608,26,"black"); UI.outline(74,441,608,26,"cyan")
        UI.rect(76+(r.center-r.width/2)*604,443,r.width*604,22,"green")
        UI.rect(75+game:marker()*604,439,2,30,"yellow")
        UI.hot("retry",74,441,608,26,nil,"Click / SPACE in the green band to align the read head")
    end
end
return Skin
