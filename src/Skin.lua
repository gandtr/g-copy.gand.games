local UI=require("src.UI")
local Skin={}; Skin.__index=Skin
local BUTTONS={
 {"START","start","Start / resume the configured disk operation"},
 {"NOCHMAL","repeat","Retry a blocked read or copy this master again"},
 {"STOP","pause","Pause / resume the drive motor"},
 {"DISK INFO","info","Read the order, track range and protection clues"},
 {"INHALT","directory","Browse your purchased master disks"},
 {"PRUEFEN","verify","Verify the completed destination / diagnose an error"},
 {"ZURUECK","defaults","Restore standard copying parameters"},
}
function Skin.new()
    local self=setmetatable({},Skin)
    self.image=love.graphics.newImage("assets/visuals/xcopy-1992.png")
    self.image:setFilter("nearest","nearest")
    self.header=love.graphics.newQuad(64,32,628,88,720,568)
    return self
end
function Skin.trackPosition(index)
    local side=math.floor((index-1)/80); local n=(index-1)%80
    return 338+side*188+n%10*16,254+math.floor(n/10)*16
end
local function field(label,value,x,w,key)
    UI.text(label,x,127,7,"cyan",w,"center")
    local hover=UI.hot("field",x,123,w,61,key,"Change "..label.."; arrows adjust numeric tracks")
    if hover then UI.rect(x,143,w,40,"dark") end
    UI.text(tostring(value),x,158,key=="mode" and 11 or 10,"yellow",w,"center")
    UI.text("+",x,144,7,"cyan",w,"center")
    UI.text("-",x,177,7,"cyan",w,"center")
end
function Skin:drive(game,index)
    local x=74+index*64; local owned=index<game.profile.drives
    local source=game.source==index; local target=game.target==index
    for _,entry in ipairs({{y=244,role="source",on=source},{y=340,role="target",on=target}}) do
        local hover=UI.hot("drive_role",x+9,entry.y,30,30,{role=entry.role,index=index},
            owned and "Select DF"..index..": as "..entry.role or "Buy external DF"..index..": at the market")
        UI.color(owned and (entry.on and "yellow" or "cyan") or "dim")
        love.graphics.circle("fill",x+24,entry.y+10,6.5)
        if owned then
            UI.color(entry.on and "white" or "cyan"); love.graphics.circle("fill",x+22,entry.y+7,2.2)
        end
        UI.rect(x+20,entry.y+17,8,4,owned and "cyan" or "dim")
        UI.rect(x+21,entry.y+22,6,2,"dim")
        UI.rect(x+21,entry.y+25,6,1,"cyan"); UI.rect(x+22,entry.y+27,4,1,"dim")
        if hover then UI.outline(x+9,entry.y,30,30,"white") end
    end
    local hover=UI.hot("drive",x,285,49,51,index,owned and "DF"..index..": insert/eject source or destination" or "Install this external drive")
    UI.rect(x,285,49,51,owned and "cyan" or "dark"); UI.outline(x,285,49,51,hover and "yellow" or "dim")
    UI.rect(x+4,287,41,26,"black"); UI.text("DRIVE",x+4,290,7,owned and "cyan" or "dim",41,"center")
    UI.text(tostring(index),x,302,9,owned and "white" or "dim",49,"center")
    if owned then
        UI.rect(x,285,3,51,{0.12,0.1,0.85}); UI.rect(x+46,285,3,51,{0.12,0.1,0.85})
        UI.rect(x+4,285,41,2,"yellow")
        UI.rect(x+8,316,32,19,"dim"); UI.rect(x+10,316,10,19,"white")
        UI.rect(x+12,318,5,14,"black"); UI.rect(x+23,316,13,19,"cyan")
    else UI.rect(x+6,318,36,4,"dim") end
    local media=game.slots[index]
    UI.text(not owned and "BUY" or media=="source" and "SRC" or media=="blank" and "DST" or "---",x,owned and 373 or 327,6,
        owned and "yellow" or "dim",49,"center")
end
function Skin:tracks(game)
    UI.text("UPPER SIDE",338,225,8,"cyan",160,"center")
    UI.text("LOWER SIDE",526,225,8,"cyan",160,"center")
    for side=0,1 do
        local left=336+side*188
        for c=0,9 do UI.text(tostring(c),left+5+c*16,240,8,"cyan") end
        for r=0,7 do UI.text(tostring(r),left-10,258+r*16,8,"cyan") end
        UI.outline(left,252,162,130,"cyan")
        for c=1,9 do UI.rect(left+c*16,252,0.65,130,"dim") end
        for r=1,7 do UI.rect(left,252+r*16,162,0.65,"dim") end
    end
    for i,state in ipairs(game.tracks) do
        local x,y=Skin.trackPosition(i)
        if state=="good" then UI.zero(x+4,y+2,"green")
        elseif state=="buffer" then UI.zero(x+4,y+2,"yellow")
        elseif tonumber(state) then UI.text(state,x+2,y+2,11,"red")
        elseif state=="skip" then UI.rect(x+6,y+7,3,1,"dim") end
        if UI.hot("track",x,y,15,15,i,"Track "..string.format("%02d",(i-1)%80)..(i<=80 and " upper" or " lower")..": "..state) then
            UI.outline(x,y,15,15,"white")
        elseif i==game.selected and game.phase=="blocked" then UI.outline(x,y,15,15,"yellow")
        elseif i==game.cursor and game:busy() then UI.outline(x,y,15,15,"cyan") end
    end
    UI.text("GREEN 0 = WRITTEN",338,385,7,"green")
    UI.text(string.format("TIME %02d:%02d",math.floor(game.time/60),math.floor(game.time)%60),534,385,8,"cyan")
end
function Skin:draw(game,settings,clock)
    love.graphics.setColor(1,1,1); love.graphics.draw(self.image,self.header,64,32)
    UI.hot("credits",64,32,628,86,nil,"X-Copy credits / sound and original art")
    UI.text("TRACK RESCUE  /  THE FLOPPY DISK BUSINESS",0,10,8,"cyan",720,"center")
    UI.outline(64,119,624,74,"cyan"); UI.rect(69,139,613,1,"dim")
    field("",game.config.mode,74,158,"mode")
    UI.text("COPY",78,127,7,"cyan")
    UI.hot("tools",148,121,71,19,nil,"TOOLS: inspect, retry, format, abort and audio")
    UI.rect(149,123,70,14,"black"); UI.text("TOOLS",150,127,7,"cyan",67,"center")
    field("START",string.format("%02d",game.config.first),247,50,"first")
    field("END",string.format("%02d",game.config.last),323,50,"last")
    field("SIDE",game.config.side,408,82,"side")
    field("SYNC",game.config.sync,505,75,"sync")
    field("LENGTH",game.config.length,593,85,"length")
    for i,button in ipairs(BUTTONS) do UI.button(button[1],77+(i-1)*86,194,82,button[2],nil,button[3]) end
    UI.text("SOURCE DRIVE",74,225,8,"cyan",240,"center")
    for i=0,3 do self:drive(game,i) end
    UI.text("TARGET DRIVE",74,384,8,"cyan",240,"center")
    self:tracks(game)
    UI.panel(59,402,638,32)
    UI.text(game.message,70,413,7,game.phase=="blocked" and "red" or "green",616)
    self:console(game,settings)
end
function Skin:console(game,settings)
    local p=game.profile
    UI.text("$"..p.money,64,448,12,"yellow")
    UI.text(p.ram.." KB RAM",176,450,8,"cyan")
    UI.text(p.drives.." DRIVE"..(p.drives==1 and "" or "S"),330,450,8,"cyan")
    UI.text(p.blanks.." BLANKS",480,450,8,"cyan")
    UI.button("MARKET",602,442,90,"market",nil,"Buy masters, blank disks and hardware upgrades")
    UI.rect(64,470,628,0.8,"dim")
    UI.text(game.job and game.job.title or "NO MASTER LOADED",64,482,9,"white")
    UI.text("STATE: "..game.phase:upper(),376,484,7,"cyan")
    UI.button(game.config.device,612,476,80,"device",nil,"DISK = direct copy with two drives; RAM = staged image buffer")
    UI.text("BUFFER",64,507,7,"cyan")
    UI.outline(118,503,204,10,"dim"); UI.rect(120,505,math.min(200,#game.buffer/math.max(1,game:capacity())*200),6,"yellow")
    UI.text(math.ceil(#game.buffer*(game.config.length=="LONG" and 6.25 or 5.5)).."/"..(p.ram-64).."K",333,507,7,"yellow")
    UI.text("HEAT",437,507,7,"cyan"); UI.outline(476,503,93,10,"dim")
    UI.rect(478,505,game.heat*0.89,6,game.heat>75 and "red" or "cyan")
    UI.button("TURBO",602,500,90,"turbo",nil,"Hold mouse / SHIFT to speed up the motor",game.turbo)
    if game.repair then
        local r=game.repair
        UI.rect(64,530,400,21,"dark")
        UI.rect(64+(r.center-r.width/2)*400,530,r.width*400,21,"green")
        UI.rect(64+(r.center-0.045)*400,530,36,21,"white")
        UI.rect(63+game:marker()*400,527,3,27,"yellow")
        UI.button("SPACE: RETRY",482,531,210,"retry",nil,"Press in green to recover the weak read")
    elseif game.phase=="complete" and game.verified then
        UI.button("DELIVER COPY  +$"..game.job.pay,64,531,280,"deliver")
        UI.text("VERIFIED AGAINST ORDER",376,538,7,"green")
    else
        UI.button("DISK INFO",64,531,108,"info")
        UI.button("MARKET",182,531,97,"market")
        UI.button("HELP",289,531,80,"help")
        UI.button("MUSIC "..(settings.music and "ON" or "OFF"),379,531,134,"music")
        UI.button("DRIVES "..(settings.sfx and "ON" or "OFF"),523,531,169,"sfx")
    end
end
return Skin
