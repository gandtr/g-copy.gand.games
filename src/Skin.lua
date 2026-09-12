-- The original screen is the skin, not a reference for a reconstructed layout.
-- Only live values, bulb states and track results are painted over its pixels.
local UI=require("src.UI")
local Skin={}; Skin.__index=Skin
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
    self.image=love.graphics.newImage("assets/visuals/xcopy-1992.png")
    self.image:setFilter("nearest","nearest")
    local function quad(x,y,w,h) return love.graphics.newQuad(x,y,w,h,720,568) end
    -- The reference's orange destination bulb already contains the original V.
    self.bulbs={off=quad(146,244,32,36),source=quad(82,244,32,36),copy=quad(82,244,32,36),verify=quad(146,340,32,36)}
    self.glyphs={}
    -- Sample the actual yellow type in the original settings, including its
    -- characteristic wide pixels. Unknown characters use the dialog font.
    local function glyphs(text,x,y)
        for i=1,#text do self.glyphs[text:sub(i,i)]=quad(x+(i-1)*16,y,16,14) end
    end
    glyphs("DOSCOPY",78,158); glyphs("BEIDE",422,158)
    glyphs("4489",516,158); glyphs("0",256,158); glyphs("1",390,158)
    glyphs("7",342,158); glyphs("DISK",602,158)
    return self
end
function Skin:originalText(text,x,y)
    for i=1,#text do
        local c=text:sub(i,i); local quad=self.glyphs[c]
        if quad then love.graphics.setColor(1,1,1); love.graphics.draw(self.image,quad,x+(i-1)*16,y)
        elseif EXTRA[c] then
            for row,bits in ipairs(EXTRA[c]) do for col=1,7 do if bits:sub(col,col)=="1" then
                UI.rect(x+(i-1)*16+(col-1)*2,y+1+(row-1)*2,2,2,{1,0.8,0})
            end end end
        elseif c~=" " then UI.text(c,x+(i-1)*16,y+1,12,"yellow") end
    end
end
function Skin.trackPosition(index)
    local side=math.floor((index-1)/80); local n=(index-1)%80
    return 338+side*188+n%10*16,254+math.floor(n/10)*16
end
function Skin:field(value,original,x,w,key)
    UI.hot("field",x,143,w,44,key,"Change "..key:upper().."; click arrows or type track numbers")
    if value~=original then
        UI.rect(x,156,w,18,"black")
        self:originalText(tostring(value),x,158)
    end
end
function Skin:drive(game,index)
    local x=82+index*64; local owned=index<game.profile.drives
    for _,entry in ipairs({{y=244,role="source"},{y=340,role="target"}}) do
        UI.rect(x,entry.y,32,36,"black")
        UI.hot("drive_role",x,entry.y,32,36,{role=entry.role,index=index},
            owned and (entry.role=="source" and "DF"..index..": select SOURCE" or "DF"..index..": OFF > COPY > V (auto verify) > OFF")
            or "DF"..index..": buy this external drive at MARKET")
        if owned then
            local mode=game.targets[index] or 0
            local state=entry.role=="source" and (game.source==index and "source" or "off") or (mode==2 and "verify" or mode==1 and "copy" or "off")
            love.graphics.setColor(1,1,1); love.graphics.draw(self.image,self.bulbs[state],x,entry.y)
        end
    end
    UI.hot("drive",74+index*64,285,49,51,index,owned and "DF"..index..": insert or eject disk / inspect target" or "Buy external DF"..index..":")
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
    love.graphics.setColor(1,1,1); love.graphics.draw(self.image,0,0)
    UI.hot("credits",64,32,628,86,nil,"Original X-Copy artwork and audio credits")
    UI.hot("mode",74,121,69,20,nil,"COPY: cycle DOSCOPY / DOSCOPY+ / NIBBLE")
    UI.hot("tools",147,121,79,20,nil,"TOOLS: market, hardware, settings, audio, help")
    self:field(game.config.mode,"DOSCOPY",78,152,"mode")
    self:field(string.format("%02d",game.config.first),"00",256,32,"first")
    self:field(string.format("%02d",game.config.last),"79",342,32,"last")
    self:field(({BOTH="BEIDE",UPPER="OBEN",LOWER="UNTEN"})[game.config.side],"BEIDE",422,80,"side")
    self:field(game.config.sync,"4489",516,64,"sync")
    self:field(game.config.device,"DISK",602,68,"device")
    UI.hot("range",249,121,151,21,nil,"Set exact track range and track length")
    UI.hot("range",301,143,22,44,nil,"Track range, side and long-track options")
    UI.hot("range",389,143,22,44,nil,"Track range, side and long-track options")
    UI.hot("side",417,121,78,21,nil,"SEITE: BOTH / UPPER / LOWER")
    UI.hot("sync",510,121,74,21,nil,"Change sync word")
    UI.hot("device",596,121,86,21,nil,"UEBER: DISK / RAM buffer route")
    for i,b in ipairs(BUTTONS) do UI.hot(b[1],77+(i-1)*86,194,82,21,nil,b[2]) end
    for i=0,3 do self:drive(game,i) end
    self:tracks(game)
    if game.time>=1 then
        UI.rect(614,382,68,12,"black")
        UI.text(string.format("%02d:%02d",math.floor(game.time/60),math.floor(game.time)%60),616,383,8,"cyan")
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
