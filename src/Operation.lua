-- The copy engine models source reads, a bounded RAM buffer, physical swaps,
-- destination writes and verification separately from the market/UI.
return function(Game)
local function indexTrack(index) return (index-1)%80 end
function Game:buildQueue()
    local queue={}
    for track=self.config.first,self.config.last do
        if self.config.side~="LOWER" then queue[#queue+1]=track+1 end
        if self.config.side~="UPPER" then queue[#queue+1]=track+81 end
    end
    return queue
end
function Game:beginCopy(useCache)
    if not self.job then return self:notice("NO MASTER DISK. VISIT THE MARKET FIRST.") end
    if self:remaining()==0 then return self:notice("THIS CUSTOMER HAS ALL THEIR COPIES. FIND A NEW ORDER AT MARKET.") end
    if self.config.first>self.config.last then return self:notice("START TRACK MUST NOT BE GREATER THAN END TRACK.") end
    if self.profile.blanks<=0 then return self:notice("NO BLANKS. BUY A FIVE-PACK FOR $6 AT THE MARKET.") end
    local queue=self:buildQueue()
    local signature=table.concat(queue,",")..self.job.id..self.config.mode..self.config.sync..self.config.length
    local cached=useCache and self.cache==signature
    self.queue,self.signature=queue,signature
    self.buffer,self.image,self.faults={},{},{}
    self.position,self.writePosition,self.cursor,self.copyClock=1,1,0,0
    self.accumulator,self.heat,self.stall,self.time=0,0,0,0
    self.health,self.combo,self.swaps,self.score=5,0,0,0
    self.blankInUse,self.verified,self.paid,self.paused=false,false,false,false
    self.repair,self.selected=nil,nil
    self.dual=self.source~=self.target and self.config.device=="DISK"
    for i=1,160 do self.tracks[i]="skip" end
    for _,index in ipairs(queue) do self.tracks[index]="empty" end
    for n=1,self.job.faults do
        local pos=math.min(#queue,math.max(1,math.floor(#queue*(n/(self.job.faults+1)))))
        self.faults[queue[pos]]=true
    end
    if cached then
        for _,index in ipairs(queue) do self.buffer[#self.buffer+1]=index; self.tracks[index]="buffer" end
        self.position=#queue+1
        self:requestSwap("blank",self.target,"writing")
        self.message="CACHED IMAGE READY. INSERT A FRESH BLANK TO REPEAT."
    else
        self.cache=nil
        self.phase=self.dual and "copying" or "reading"
        if self.slots[self.source]~="source" then self:requestSwap("source",self.source,self.phase)
        elseif self.dual then self:requestSwap("blank",self.target,"copying")
        else self.message="READING MASTER INTO "..(self.profile.ram-64).." KB USABLE RAM." end
    end
    self:emit("startup"); return true
end
function Game:start()
    if self.paused then self.paused=false; return true end
    if self.phase=="blocked" then return self:retry() end
    if self.phase=="swap" then return self:loadMedia(self.swapDrive,self.swapMedia) end
    if self:busy() or self.phase=="verifying" then return self:notice("DRIVE ALREADY RUNNING. STOP PAUSES THE OPERATION.") end
    return self:beginCopy(false)
end
function Game:repeatCopy()
    if self.phase=="blocked" then return self:retry() end
    if self:busy() or self.phase=="verifying" then return self:notice("NOCHMAL RETRIES A BLOCKED TRACK OR REPEATS A FINISHED COPY.") end
    return self:beginCopy(true)
end
function Game:protectionError(index)
    if self.job.protection~=indexTrack(index) then return nil end
    if self.job.mode=="NIBBLE" and self.config.mode~="NIBBLE" then return "5","CUSTOM HEADER: SELECT NIBBLE, THEN NOCHMAL." end
    if self.config.sync~=self.job.sync then return "2","NO SYNC. DISK INFO HAS THE SYNC WORD. CHANGE SYNC + NOCHMAL." end
    if self.job.length=="LONG" and self.config.length~="LONG" then return "7","LONG TRACK. SELECT LONG LENGTH, THEN NOCHMAL." end
end
function Game:block(index, code, message)
    self.beforeBlock,self.phase,self.selected=self.phase,"blocked",index
    self.tracks[index]=code; self.message=message; self:emit("fault")
end
function Game:retry()
    if self.phase~="blocked" or self.paused then return false end
    if self.repair then return self:hit() end
    local code,message=self:protectionError(self.selected)
    if code then self.tracks[self.selected]=code; return self:notice(message) end
    if self.faults[self.selected] then
        self.repair={index=self.selected,elapsed=0,center=0.35+self:random()*0.3,width=0.25,period=1.7}
        self.message="WEAK READ: PRESS SPACE WITH THE MARKER IN GREEN."
    else self.phase=self.beforeBlock; self.tracks[self.selected]="empty"; self.message="PROFILE CORRECTED. READING THE TRACK AGAIN." end
    self:emit("seek"); return true
end
function Game:marker()
    if not self.repair then return 0 end
    local v=(self.repair.elapsed/self.repair.period)%2; return v<=1 and v or 2-v
end
function Game:hit()
    if self.phase~="blocked" or self.paused then return end
    if not self.repair then return self:retry() end
    local r=self.repair; local distance=math.abs(self:marker()-r.center); self.repair=nil
    if distance<=r.width/2 then
        self.faults[r.index]=nil; self.tracks[r.index]="empty"; self.phase=self.beforeBlock
        self.combo=self.combo+1; self.score=self.score+(distance<0.045 and 150 or 80)
        self.message="READ HEAD ALIGNED. COPYING RESUMED."; self:emit("perfect")
    else
        self.health=self.health-1; self.combo=0; self.message="READ MISSED. NOCHMAL TO TRY AGAIN."
        self:emit("miss")
        if self.health<=0 then self.phase="failed"; self.message="MEDIA FAILED. NOCHMAL STARTS A FRESH COPY." end
    end
end
function Game:cancelRepair() if self.repair then self.repair=nil; return true end; return false end
function Game:readTrack()
    local index=self.queue[self.position]
    if not index then return end
    self.cursor=index
    local code,message=self:protectionError(index)
    if code then self:block(index,code,message); return end
    if self.faults[index] then
        if self.config.mode=="DOSCOPY+" then self.faults[index]=nil
        else self:block(index,"6","CHECKSUM ERROR 6. NOCHMAL / SPACE TO CALIBRATE THE HEAD."); return end
    end
    self.position=self.position+1; self.image[#self.image+1]=index
    if self.dual then self.tracks[index]="good"
    else self.tracks[index]="buffer"; self.buffer[#self.buffer+1]=index end
    self:emit("track")
    if self.dual and self.position>#self.queue then self:copyFinished()
    elseif not self.dual and (#self.buffer>=self:capacity() or self.position>#self.queue) then
        self.writePosition=1
        self:requestSwap("blank",self.target,"writing")
    end
end
function Game:writeTrack()
    local index=self.buffer[self.writePosition]
    if not index then return end
    self.cursor=index; self.tracks[index]="good"; self.writePosition=self.writePosition+1; self:emit("track")
    if self.writePosition>#self.buffer then
        self.buffer={}; self.writePosition=1
        if self.position>#self.queue then self:copyFinished()
        else self:requestSwap("source",self.source,"reading") end
    end
end
function Game:copyFinished()
    self.phase,self.turbo="complete",false
    if self:capacity()>=#self.queue then
        self.cache=table.concat(self.queue,",")..self.job.id..self.config.mode..self.config.sync..self.config.length
    end
    self.message="COPY FINISHED. CLICK PRUEFEN / CHECKDISK TO VERIFY BEFORE DELIVERY."
    self:emit("disk")
end
function Game:verify()
    if self.phase=="blocked" then
        local _,message=self:protectionError(self.selected)
        return self:notice(message or "ERROR 6: USE DOSCOPY+ OR NOCHMAL TO CALIBRATE THE READ HEAD.")
    end
    if self.phase~="complete" then return self:notice("CHECKDISK NEEDS A FINISHED COPY. DISK INFO SHOWS THE ORDER.") end
    self.phase,self.verifyPosition,self.copyClock="verifying",1,0
    self.message="VERIFYING DESTINATION AGAINST THE CUSTOMER'S TRACK MANIFEST."
    self:emit("startup"); return true
end
function Game:verifyFinished()
    self.phase="complete"
    for i=1,160 do
        local track,side=indexTrack(i),i<=80 and "UPPER" or "LOWER"
        local needed=track>=self.job.first and track<=self.job.last and (self.job.side=="BOTH" or self.job.side==side)
        if (self.tracks[i]=="good")~=needed then
            self.verified=false
            return self:notice("ORDER MISMATCH: CHECK START / END / SIDE IN DISK INFO. REPEAT THE COPY.")
        end
    end
    self.verified=true; self.message="VERIFIED! DELIVER FOR $"..self.job.pay.." OR USE NOCHMAL AFTER DELIVERY."
    self:emit("disk")
end
function Game:deliver()
    if self.phase~="complete" or not self.verified or self.paid then return self:notice("FINISH AND VERIFY THIS COPY BEFORE DELIVERY.") end
    if self:remaining()<=0 then return false end
    local p=self.profile
    p.money=p.money+self.job.pay; p.completed=p.completed+1
    p.delivered[self.job.id]=(p.delivered[self.job.id] or 0)+1
    self.paid,self.phase=true,"delivered"
    self.message="PAID $"..self.job.pay..". "..self:remaining().." COPIES STILL ORDERED. MARKET HAS NEW STOCK."
    self:emit("save"); self:emit("win"); return true
end
function Game:step(dt, boost)
    self.time=self.time+dt
    self.turbo=boost and (self.phase=="reading" or self.phase=="writing" or self.phase=="copying") and self.stall<=0
    self.heat=math.max(0,self.heat+(self.turbo and 26 or -20)*dt)
    if self.heat>=100 then self.heat=99; self.stall=2; self.turbo=false; self.message="MOTOR TOO HOT. COOLING FOR TWO SECONDS."; self:emit("miss") end
    if self.stall>0 then self.stall=math.max(0,self.stall-dt); return end
    if self.phase=="blocked" then if self.repair then self.repair.elapsed=self.repair.elapsed+dt end; return end
    local rate=self.phase=="verifying" and 48 or (self.turbo and 32 or 18)
    if self.config.mode=="NIBBLE" and self.phase~="verifying" then rate=rate*0.75
    elseif self.config.mode=="DOSCOPY+" and self.phase~="verifying" then rate=rate*0.85 end
    self.copyClock=self.copyClock+dt*rate
    while self.copyClock>=1-1e-9 do
        self.copyClock=math.max(0,self.copyClock-1)
        if self.phase=="reading" or self.phase=="copying" then self:readTrack()
        elseif self.phase=="writing" then self:writeTrack()
        elseif self.phase=="verifying" then
            self.verifyPosition=self.verifyPosition+1
            if self.verifyPosition>#self.queue then self:verifyFinished() end
        else break end
        if self.phase=="swap" or self.phase=="blocked" or self.phase=="complete" then self.copyClock=0; break end
    end
end
function Game:update(dt, boost)
    if self.paused or self.phase=="swap" or (not self:busy() and self.phase~="verifying") then return end
    self.accumulator=(self.accumulator or 0)+dt
    while self.accumulator>=1/120-1e-9 do
        self.accumulator=math.max(0,self.accumulator-1/120); self:step(1/120,boost)
        if self.phase=="swap" or self.phase=="complete" or self.phase=="failed" then self.accumulator=0; break end
    end
end
end
