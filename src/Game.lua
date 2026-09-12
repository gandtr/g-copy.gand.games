local Catalog = require("src.Catalog")
local Game = {}; Game.__index = Game
function Game.new(seed, profile)
    local self = setmetatable({}, Game)
    self.profile = profile or {money=40, ram=512, drives=1, blanks=3, completed=0, owned={}, delivered={}}
    self.rng = (seed or os.time()) % 2147483647
    if self.rng == 0 then self.rng = 1 end
    self.events, self.slots, self.tracks = {}, {}, {}
    self.source, self.target = 0, self.profile.drives > 1 and 1 or 0
    self.config = {first=0, last=79, side="BOTH", mode="DOSCOPY", sync="4489", length="NORMAL", device="DISK"}
    self.phase, self.paused, self.heat, self.stall = "idle", false, 0, 0
    self.time, self.score, self.combo, self.health = 0, 0, 0, 5
    self.cursor, self.position, self.buffer, self.swaps = 0, 1, {}, 0
    self.message = "WELCOME. OPEN THE MARKET TO BUY YOUR FIRST MASTER DISK."
    for i=1,160 do self.tracks[i]="empty" end
    if self.profile.selected then
        local job=Catalog.get(self.profile.selected)
        if job and self.profile.owned[job.id] then self:selectJob(job.id) end
    end
    return self
end
function Game:random() self.rng=self.rng*16807%2147483647; return self.rng/2147483647 end
function Game:emit(kind, value) self.events[#self.events+1]={kind=kind,value=value} end
function Game:drainEvents() local events=self.events; self.events={}; return events end
function Game:notice(message) self.message=message; self:emit("ui"); return false end
function Game:busy()
    return self.phase=="reading" or self.phase=="writing" or self.phase=="copying" or self.phase=="swap" or self.phase=="blocked" or self.phase=="verifying"
end
function Game:remaining(job)
    job=job or self.job
    return job and math.max(0,job.demand-(self.profile.delivered[job.id] or 0)) or 0
end
function Game:selectJob(id)
    if self:busy() then return self:notice("FINISH THIS COPY OR USE TOOLS > ABORT BEFORE CHANGING DISKS.") end
    local job=Catalog.get(id)
    if not job or not self.profile.owned[id] then return false end
    self.job, self.profile.selected = job, id
    self.phase, self.paused, self.cache = "idle", false, nil
    self.slots[self.source]="source"
    self.message="LOADED "..job.title..". DISK INFO HAS THE CUSTOMER'S INSTRUCTIONS."
    for i=1,160 do self.tracks[i]="empty" end
    self:emit("save"); return true
end
function Game:buyMaster(id)
    if self:busy() then return self:notice("FINISH OR ABORT THE CURRENT OPERATION FIRST.") end
    local job=Catalog.get(id); if not job then return false end
    if self.profile.completed<job.unlock then return self:notice("BUILD YOUR REPUTATION: COMPLETE MORE COPIES TO UNLOCK THIS DISK.") end
    if not self.profile.owned[id] then
        if self.profile.money<job.cost then return self:notice("NOT ENOUGH CASH FOR THAT MASTER DISK.") end
        self.profile.money=self.profile.money-job.cost; self.profile.owned[id]=true
    end
    return self:selectJob(id)
end
function Game:buyUpgrade(id)
    if self:busy() then return self:notice("SHUT DOWN THE COPY BEFORE INSTALLING HARDWARE.") end
    for _, item in ipairs(Catalog.upgrades) do if item.id==id then
        local p=self.profile
        if (item.ram and p.ram~=item.requiresRam) or (item.drives and p.drives~=item.requiresDrives) then
            return self:notice("THIS UPGRADE IS ALREADY FITTED OR NEEDS ITS PREVIOUS MODEL.")
        end
        if p.money<item.cost then return self:notice("NOT ENOUGH CASH. DELIVER MORE COPIES.") end
        p.money=p.money-item.cost
        if item.ram then p.ram=item.ram else p.drives=item.drives; self.target=p.drives-1 end
        self.message="INSTALLED "..item.label..". READY FOR WORK."
        self:emit("save"); return true
    end end
    return false
end
function Game:renewOrders()
    if self:busy() then return self:notice("FINISH OR ABORT THE CURRENT COPY FIRST.") end
    local count=0
    for _,job in ipairs(Catalog.jobs) do
        if self.profile.owned[job.id] and self:remaining(job)==0 then
            self.profile.delivered[job.id]=0; count=count+1
        end
    end
    self.message=count>0 and "NEW CUSTOMERS PLACED ORDERS FOR YOUR SOLD-OUT TITLES." or "CURRENT CUSTOMERS STILL NEED THEIR COPIES."
    self:emit("save"); return count>0
end
function Game:buyBlanks()
    if self.profile.money<6 then return self:notice("A FIVE-PACK OF BLANKS COSTS $6.") end
    local ownsMaster=false
    for _,owned in pairs(self.profile.owned) do if owned then ownsMaster=true end end
    if not ownsMaster and self.profile.money<16 then return self:notice("KEEP $10 FOR YOUR FIRST MASTER. YOU ALREADY HAVE STARTER BLANKS.") end
    self.profile.money=self.profile.money-6; self.profile.blanks=self.profile.blanks+5
    self.message="FIVE FRESH BLANK DISKS ADDED."; self:emit("save"); return true
end
function Game:setDrive(role, index)
    if self:busy() then return self:notice("DRIVE ROUTING IS LOCKED UNTIL THIS COPY FINISHES.") end
    if index>=self.profile.drives then return self:notice("DRIVE NOT CONNECTED. BUY IT AT THE HARDWARE COUNTER.") end
    self[role]=index
    self.message=string.format("%s SET TO DF%d:. CLICK THE DRIVE TO INSERT MEDIA.",role:upper(),index)
    return true
end
function Game:setConfig(key, value)
    if self:busy() and (key=="first" or key=="last" or key=="side" or key=="device") then
        return self:notice("FINISH OR ABORT BEFORE CHANGING THE TRACK RANGE OR BUFFER ROUTE.")
    end
    if (key=="first" or key=="last") and (type(value)~="number" or value<0 or value>79) then return false end
    local allowed={side={BOTH=true,UPPER=true,LOWER=true},mode={DOSCOPY=true,["DOSCOPY+"]=true,NIBBLE=true},
        sync={["4489"]=true,A245=true,["8914"]=true},length={NORMAL=true,LONG=true},device={DISK=true,RAM=true}}
    if allowed[key] and not allowed[key][value] then return false end
    if not allowed[key] and key~="first" and key~="last" then return false end
    self.config[key]=value; self.message=key:upper().." SET TO "..tostring(value).."."
    return true
end
function Game:defaults()
    if self:busy() then return self:notice("FINISH OR ABORT BEFORE RESTORING DEFAULTS.") end
    self.config={first=0,last=79,side="BOTH",mode="DOSCOPY",sync="4489",length="NORMAL",device="DISK"}
    self.message="STANDARD DISK SETTINGS RESTORED."
end
function Game:loadMedia(index, media)
    if index>=self.profile.drives then return self:notice("THIS DRIVE IS NOT CONNECTED.") end
    if media~="source" and media~="blank" and media~="empty" then return false end
    if self.phase=="swap" then
        if index~=self.swapDrive or media~=self.swapMedia then
            return self:notice(string.format("NEED %s IN DF%d: TO CONTINUE.",self.swapMedia:upper(),self.swapDrive))
        end
        if media=="blank" and not self.blankInUse then
            if self.profile.blanks<=0 then return self:notice("NO BLANKS LEFT. BUY A FIVE-PACK IN THE MARKET.") end
            self.profile.blanks=self.profile.blanks-1; self.blankInUse=true
        end
        self.slots[index]=media; self.phase=self.afterSwap; self.swaps=self.swaps+1
        self.message="DISK INSERTED. "..self.phase:upper().."..."
        if media=="source" and self.phase=="copying" and not self.blankInUse then
            self:requestSwap("blank",self.target,"copying")
        end
        self:emit("startup"); self:emit("save"); return true
    end
    if self:busy() then return self:notice("STOP: A DISK IS IN USE. WAIT FOR THE SWAP REQUEST.") end
    if media=="source" and not self.job then return self:notice("BUY A MASTER DISK IN THE MARKET FIRST.") end
    self.slots[index]=media; self.message=media:upper().." INSERTED IN DF"..index..":"
    self:emit("startup"); return true
end
function Game:capacity() return math.floor((self.profile.ram-64)/(self.config.length=="LONG" and 6.25 or 5.5)) end
function Game:requestSwap(media, drive, after)
    self.phase,self.swapMedia,self.swapDrive,self.afterSwap="swap",media,drive,after
    self.message=string.format("INSERT %s IN DF%d:  /  %d KB BUFFERED",media:upper(),drive,math.ceil(#self.buffer*5.5))
    self:emit("seek")
end
function Game:togglePause()
    if self:busy() and self.phase~="swap" then self.paused=not self.paused; self.turbo=false end
end
function Game:abort()
    self.phase,self.paused,self.repair,self.cache="idle",false,nil,nil
    self.buffer,self.blankInUse={},false; self.message="OPERATION ABORTED. CONFIGURE AND START A NEW COPY."
end
require("src.Operation")(Game)
return Game
