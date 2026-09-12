local Game=require("src.Game")
local App={}; App.__index=App
local CHOICES={mode={"DOSCOPY","DOSCOPY+","NIBBLE"},side={"BOTH","UPPER","LOWER"},
    sync={"4489","A245","8914"},length={"NORMAL","LONG"},device={"DISK","RAM"}}
function App.new(settings,profile,seed)
    local self=setmetatable({settings=settings,game=Game.new(seed,profile),marketTab="masters",marketPage=0},App)
    if not self.game.job then self.page="market" end
    return self
end
function App:cycle(key,delta)
    local choices=CHOICES[key]; local current=1
    for i,value in ipairs(choices) do if value==self.game.config[key] then current=i end end
    self.game:setConfig(key,choices[(current-1+(delta or 1))%#choices+1])
end
function App:open(page)
    self.page=page; self.turboHeld=false; self.editKey=nil
end
function App:applyEdit()
    if self.editKey then
        local value=tonumber(self.editText)
        if value and value>=0 and value<=79 then self.game:setConfig(self.editKey,value)
        else self.game:notice("TRACK NUMBERS MUST BE 00 THROUGH 79.") end
        self.editKey=nil
    end
end
function App:action(id,value,y)
    local g=self.game
    if CHOICES[id] then self:cycle(id); return end
    if id=="close" then self:applyEdit(); self.page=nil
    elseif id=="market" then self:open("market")
    elseif id=="directory" then self.marketTab="collection"; self.marketPage=0; self:open("market")
    elseif id=="market_tab" then self.marketTab=value; self.marketPage=0
    elseif id=="market_page" then self.marketPage=(self.marketPage+value)%2
    elseif id=="master" then if g:buyMaster(value) then self:open("info") end
    elseif id=="upgrade" then g:buyUpgrade(value)
    elseif id=="blanks" then g:buyBlanks()
    elseif id=="orders" then g:renewOrders()
    elseif id=="info" or id=="help" or id=="tools" or id=="credits" or id=="range" or id=="status" then self:open(id)
    elseif id=="drive" then
        if value>=g.profile.drives then self.marketTab="hardware"; self:open("market")
        else self.driveIndex=value; self:open("drive") end
    elseif id=="drive_role" then
        if value.index>=g.profile.drives then self.marketTab="hardware"; self:open("market")
        else g:setDrive(value.role,value.index) end
    elseif id=="media" then if g:loadMedia(value.index,value.media) then self.page=nil end
    elseif id=="swap" then g:loadMedia(g.swapDrive,g.swapMedia)
    elseif id=="field" then
        if value=="first" or value=="last" then
            if y and y<155 then g:setConfig(value,math.min(79,g.config[value]+1))
            elseif y and y>173 then g:setConfig(value,math.max(0,g.config[value]-1))
            else self:open("range"); self.editKey=value; self.editText="" end
        else self:cycle(value,y and y>173 and -1 or 1) end
    elseif id=="adjust" then g:setConfig(value.key,math.max(0,math.min(79,g.config[value.key]+value.delta)))
    elseif id=="edit" then self:applyEdit(); self.editKey=value; self.editText=""
    elseif id=="start" then self.page=nil; g:start()
    elseif id=="repeat" then self.page=nil; g:repeatCopy()
    elseif id=="retry" then g:hit()
    elseif id=="pause" then g:togglePause()
    elseif id=="verify" then self.page=nil; g:verify()
    elseif id=="deliver" then g:deliver()
    elseif id=="defaults" then g:defaults()
    elseif id=="abort" then g:abort(); self.page=nil
    elseif id=="format" then
        if g:busy() or g.phase=="verifying" then g:notice("ABORT OR FINISH COPYING BEFORE FORMATTING.")
        else
            g:abort(); for _,drive in ipairs(g:selectedTargets()) do g.slots[drive]="blank" end
            for i=1,160 do g.tracks[i]="empty" end
            g.message="TARGET FORMATTED. PREVIOUS COPY CLEARED. READY FOR A NEW WRITE."
            self.page=nil
        end
    elseif id=="music" or id=="sfx" then
        self.settings[id]=not self.settings[id]; g:emit("save")
    elseif id=="turbo" then self.turboHeld=true
    elseif id=="track" then
        local state=g.tracks[value]
        if value==g.selected and g.phase=="blocked" then g:retry()
        else g:notice(string.format("TRACK %02d %s: %s",(value-1)%80,value<=80 and "UPPER" or "LOWER",state:upper())) end
    end
end
function App:key(key)
    if self.editKey then
        if key=="return" then self:applyEdit()
        elseif key=="backspace" then self.editText=self.editText:sub(1,-2)
        elseif key=="escape" then self.editKey=nil end
        return
    end
    if key=="m" then self:action("music"); return end
    if key=="s" then self:action("sfx"); return end
    local pageKeys={h="help",c="credits",b="market",i="info"}
    if pageKeys[key] then
        if self.page==pageKeys[key] then self.page=nil else self:open(pageKeys[key]) end
        return
    end
    if self.page then if key=="return" or key=="escape" then self.page=nil end; return end
    if key=="return" then
        if self.game.phase=="complete" and self.game.verified then self:action("deliver")
        else self:action("start") end
    elseif key=="space" then
        if self.game.phase=="swap" then self:action("swap") else self:action("repeat") end
    elseif key=="p" then self:action("pause")
    elseif key=="r" then self:action("repeat")
    elseif key=="v" then self:action("verify")
    elseif key=="escape" then if not self.game:cancelRepair() then self:action("pause") end end
end
return App
