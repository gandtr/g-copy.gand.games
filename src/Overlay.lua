local UI=require("src.UI")
local Catalog=require("src.Catalog")
local Overlay={}
local function header(title)
    UI.regions={}
    UI.panel(64,119,628,435)
    UI.text(title,80,137,14,"yellow")
    UI.button("X",650,128,28,"close",nil,"Close this panel and return to the copy desk")
    UI.rect(80,165,596,1,"dim")
end
local function line(text,y,color) UI.text(text,84,y,8,color or "cyan",584) end
local function row(label,value,y,action)
    UI.text(label,86,y+6,8,"cyan"); UI.button(value,395,y,267,action)
end
function Overlay.market(app)
    local g,p=app.game,app.game.profile
    header("THE SATURDAY DISK MARKET")
    UI.text("CASH $"..p.money.."  /  "..p.completed.." COPIES DELIVERED",84,179,8,"white")
    UI.button("MASTER DISKS",84,201,184,"market_tab","masters",nil,app.marketTab=="masters")
    UI.button("HARDWARE",280,201,184,"market_tab","hardware",nil,app.marketTab=="hardware")
    UI.button("MY COLLECTION",476,201,192,"market_tab","collection",nil,app.marketTab=="collection")
    if app.marketTab=="hardware" then
        for i,item in ipairs(Catalog.upgrades) do
            local y=237+(i-1)*49
            local owned=(item.ram and p.ram>=item.ram) or (item.drives and p.drives>=item.drives)
            UI.text(item.label,86,y+2,9,"white")
            UI.text(item.note,86,y+21,6,"cyan",420)
            UI.button(owned and "INSTALLED" or "$"..item.cost,545,y+2,119,"upgrade",item.id)
        end
    else
        local jobs={}
        for _,job in ipairs(Catalog.jobs) do
            if app.marketTab~="collection" or p.owned[job.id] then jobs[#jobs+1]=job end
        end
        local start=app.marketPage*6+1
        for n=0,5 do
            local job=jobs[start+n]
            if job then
                local x=84+(n%2)*300; local y=236+math.floor(n/2)*84
                UI.outline(x,y,284,77,"dim")
                UI.text(job.title,x+9,y+9,9,p.completed>=job.unlock and "white" or "dim")
                UI.text(job.kind,x+9,y+26,6,"cyan")
                UI.text("PAYS $"..job.pay.." / "..g:remaining(job).." LEFT",x+9,y+41,7,"green")
                local label=p.owned[job.id] and "LOAD" or "BUY $"..job.cost
                if p.completed<job.unlock then label="NEEDS "..job.unlock.." SALES" end
                UI.button(label,x+9,y+52,266,"master",job.id,job.note)
            end
        end
        if #jobs==0 then line("Your shelf is empty. Buy a master disk to begin.",260) end
        if #jobs>6 then
            UI.button("<",84,492,30,"market_page",-1)
            UI.text("PAGE "..(app.marketPage+1),122,499,6,"cyan")
            UI.button(">",171,492,30,"market_page",1)
        end
    end
    UI.button("GAND.GAMES",208,493,92,"link","https://gand.games","Visit the Gand Games studio site")
    UI.button("NEW ORDERS",309,493,130,"orders",nil,"New customers reorder sold-out titles you already own")
    UI.button("5 BLANK DISKS  $6",450,493,216,"blanks")
    UI.text("Masters stay in your collection. Each customer has a limited order.",84,531,7,"dim")
end
function Overlay.info(app)
    local g=app.game
    header("DISK INFO / CUSTOMER ORDER")
    if not g.job then line("No master loaded. Buy one at the market.",190); UI.button("VISIT MARKET",84,233,580,"market"); return end
    local job=g.job
    line(job.title.."  /  "..job.kind,184,"white")
    UI.text(job.brief,84,211,8,"cyan",575)
    UI.text(job.note,84,251,8,"yellow",575)
    UI.rect(84,292,580,1,"dim")
    line(string.format("REQUIRED: %02d-%02d / %s / $%d PER VERIFIED COPY",job.first,job.last,job.side,job.pay),309,"green")
    line("ORDER REMAINING: "..g:remaining().."  /  MASTER PURCHASED: YES",338)
    line("CURRENT: "..string.format("%02d-%02d",g.config.first,g.config.last).." / "..g.config.side.." / "..g.config.mode,367)
    line("USABLE RAM: "..(g.profile.ram-64).." KB  /  BUFFER: "..g:capacity().." SIDE-TRACKS",396)
    UI.text("Yellow 0 = in RAM. Green 0 = on destination. Red number = read error.\n512 KB includes 64 KB for the copier. Full standard disk = 880 KB.",84,429,7,"cyan",580)
    UI.button("CONFIGURE TRACKS",84,490,280,"range")
    UI.button("BACK TO COPY DESK",380,490,284,"close")
end
function Overlay.range(app)
    local g=app.game
    header("TRACK RANGE / COPY PROFILE")
    UI.text("Click a number and type 00-79. ENTER applies it.",84,184,8,"cyan")
    for n,key in ipairs({"first","last"}) do
        local y=218+(n-1)*55
        UI.text(key=="first" and "START TRACK" or "END TRACK",84,y+6,9,"white")
        UI.button("-10",241,y,57,"adjust",{key=key,delta=-10})
        UI.button("-1",305,y,48,"adjust",{key=key,delta=-1})
        UI.button(app.editKey==key and (app.editText.."_") or string.format("%02d",g.config[key]),360,y,89,"edit",key)
        UI.button("+1",456,y,48,"adjust",{key=key,delta=1})
        UI.button("+10",511,y,57,"adjust",{key=key,delta=10})
    end
    row("SIDE",g.config.side,329,"side")
    row("COPY MODE",g.config.mode,362,"mode")
    row("SYNC WORD",g.config.sync,395,"sync")
    row("TRACK LENGTH",g.config.length,428,"length")
    row("BUFFER DEVICE",g.config.device,461,"device")
    UI.button("RETURN TO DESK",84,503,578,"close")
end
function Overlay.drive(app)
    local g,index=app.game,app.driveIndex
    header("DF"..index..": MEDIA BAY")
    line("LOWER BULB: OFF > COPY > V (AUTO VERIFY) > OFF.",188)
    line("INSERTED: "..(g.slots[index] or "empty"):upper(),224,"white")
    if g.phase=="swap" then line("THE COPIER NEEDS: "..g.swapMedia:upper().." IN DF"..g.swapDrive..":",257,"yellow") end
    UI.button("INSERT MASTER / SOURCE",84,299,580,"media",{index=index,media="source"})
    UI.button("INSERT DESTINATION / BLANK",84,332,580,"media",{index=index,media="blank"})
    UI.button("EJECT",84,365,580,"media",{index=index,media="empty"})
    UI.button("USE AS SOURCE",84,414,280,"drive_role",{index=index,role="source"})
    UI.button("TARGET: "..({[0]="OFF",[1]="COPY",[2]="V"})[g.targets[index] or 0],380,414,284,"drive_role",{index=index,role="target"})
    local copy=g.copies[index]
    UI.text(copy and ("THIS DISK: "..(copy.verified and "VERIFIED" or "NOT VERIFIED").." / "..(copy.mode==2 and "AUTOMATIC V" or "MANUAL CHECK"))
        or "Select several external targets to copy in parallel.\nEach target needs one blank and one remaining customer order.",84,463,8,"cyan",580)
end
function Overlay.tools(app)
    header("TOOLS")
    local entries={{"MARKET / MASTERS / HARDWARE","market"},{"TRACK RANGE / LENGTH / BUFFER","range"},
        {"CHECKDISK / DIAGNOSE","verify"},{"NOCHMAL / RETRY OR REPEAT","repeat"},
        {"DISK INFORMATION","info"},{"FORMAT TARGET DISK","format"},{"ABORT CURRENT COPY","abort"},
        {"BUSINESS / OPERATION STATUS","status"},{"HELP","help"},{"CREDITS + GAND GAMES LINKS","credits"}}
    for i,e in ipairs(entries) do UI.button(e[1],84,179+(i-1)*30,580,e[2]) end
    UI.button("MUSIC "..(app.settings.music and "ON" or "OFF"),84,491,280,"music")
    UI.button("SFX "..(app.settings.sfx and "ON" or "OFF"),384,491,280,"sfx")
end
function Overlay.status(app)
    local g,p=app.game,app.game.profile
    header("COPY DESK / BUSINESS STATUS")
    line("CASH $"..p.money.." / "..p.ram.." KB / "..p.drives.." DRIVES / "..p.blanks.." BLANKS",184,"white")
    UI.text(g.message,84,219,9,"yellow",580)
    line(g.job and g.job.title or "NO MASTER LOADED",279)
    line("STATE: "..g.phase:upper().." / BUFFER: "..#g.buffer.." TRACKS / HEAT: "..math.floor(g.heat).."%",309)
    for n,drive in ipairs(g:selectedTargets()) do
        local copy=g.copies[drive]
        line("DF"..drive..": "..(g.targets[drive]==2 and "V - AUTO VERIFY" or "COPY - MANUAL VERIFY")..(copy and (copy.verified and " / VERIFIED" or " / UNVERIFIED") or ""),333+n*27)
    end
    if g.phase=="complete" and g.verified then UI.button("DELIVER BATCH +$"..g:payout(),84,457,580,"deliver")
    else UI.button("CHECKDISK / VERIFY TARGETS",84,457,580,"verify") end
    UI.button("MARKET",84,493,280,"market"); UI.button("RETURN TO DESK",384,493,280,"close")
end
function Overlay.help(app)
    header("A SMALL DESK. A BIG DISK BUSINESS.")
    local lines={
        "1. MARKET: buy a master. DISK INFO shows the order.",
        "2. Set START / END tracks, SIDE, MODE, SYNC and LENGTH.",
        "3. Upper bulb = source. Lower: OFF > COPY > V > OFF.",
        "   Select several external targets for parallel copies.",
        "4. START reads. With 512K, swap SRC > DST > SRC > DST.",
        "5. Red 2/5/7? Read the clue, change the profile, NOCHMAL.",
        "   Red 6? NOCHMAL + timed SPACE, or try DOSCOPY+.",
        "6. V auto-verifies. PRUEFEN checks copy-only targets.",
        "7. NOCHMAL repeats. RAM caches images; external drives",
        "   Click the VERIFIED status / ENTER to deliver the batch.",
        "TAB / SHIFT+TAB select. ENTER activate. B market. H help.",
        "SHIFT turbo. M music. S drive sounds. F11 fullscreen.",
    }
    for i,text in ipairs(lines) do UI.text(text,84,181+(i-1)*25,8,i==11 and "yellow" or "cyan",585) end
    UI.button("BACK TO WORK",84,510,580,"close")
end
function Overlay.credits(app)
    header("THE SOUND OF COPYING")
    line("G-COPY PROFESSIONAL / GAND",193,"white")
    line("G-COPY artwork supplied by Gand. Live controls and copy results.",226)
    line("SUCCESS MARK: GREEN ZERO (X-COPY SHRINE ERROR REFERENCE)",269,"green")
    line("A500 DRIVE AUDIO + A600 INSERT / EJECT (ASIE / CC0)",308,"white")
    line("MUSIC: ADVENTURE BEGINS LOOP / HOLIZNA / CC0",347,"white")
    UI.text("Full asset sources and licenses are in docs/ASSETS.md.\nAll market software and protection puzzles are imaginary.\nBusiness progress is saved; active copying restarts on relaunch.",84,390,8,"cyan",580)
    UI.text("A GAND GAMES PRODUCTION",84,440,9,"yellow")
    UI.button("GAND.GAMES",84,456,580,"link","https://gand.games","Visit the Gand Games studio site")
    UI.button("BACK",84,505,580,"close")
end
function Overlay.draw(app)
    local page=app.page; local g=app.game
    if page and Overlay[page] then Overlay[page](app)
    elseif g.phase=="swap" then
        UI.regions={}; UI.panel(138,246,504,133)
        UI.text("SWAP FLOPPY DISK",148,260,14,"yellow",484,"center")
        UI.text("INSERT "..g.swapMedia:upper().." IN DF"..g.swapDrive..":",148,286,10,"white",484,"center")
        UI.text(#g.buffer.." TRACKS BUFFERED / "..g.swaps.." SWAPS SO FAR",148,309,7,"cyan",484,"center")
        UI.button("INSERT "..g.swapMedia:upper().." / ENTER",164,342,449,"swap")
        UI.hot("drive",74+g.swapDrive*64,285,49,51,g.swapDrive,"Open the requested media bay")
    elseif g.paused then
        UI.regions={}; UI.panel(138,246,504,133)
        UI.text("DRIVE STOPPED",148,268,14,"yellow",484,"center")
        UI.text("READ BUFFER PRESERVED. MOTOR PAUSED.",148,305,8,"cyan",484,"center")
        UI.button("START / P TO RESUME",164,342,449,"pause")
    end
end
return Overlay
