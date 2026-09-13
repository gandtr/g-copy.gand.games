local Catalog=require("src.Catalog")
local Storage={}
function Storage.defaults()
    return {best=0,music=true,sfx=true}, {money=40,ram=512,drives=1,blanks=3,completed=0,owned={},delivered={}}
end
function Storage.encode(settings,p)
    local lines={"version=2","money="..p.money,"ram="..p.ram,"drives="..p.drives,"blanks="..p.blanks,
        "completed="..p.completed,"music="..(settings.music and 1 or 0),"sfx="..(settings.sfx and 1 or 0),
        "best="..settings.best,"selected="..(p.selected or "")}
    for _,job in ipairs(Catalog.jobs) do
        lines[#lines+1]="owned_"..job.id.."="..(p.owned[job.id] and 1 or 0)
        lines[#lines+1]="delivered_"..job.id.."="..(p.delivered[job.id] or 0)
    end
    return table.concat(lines,"\n").."\n"
end
function Storage.decode(data)
    local settings,p=Storage.defaults(); local fields={}
    if not data then return settings,p end
    for key,value in data:gmatch("([%w_]+)=([^\n]*)") do fields[key]=value end
    local function number(key,default,max)
        local n=tonumber(fields[key]); if not n or n~=n then return default end
        return math.floor(math.max(0,math.min(max,n)))
    end
    settings.best=number("best",0,99999999); settings.music=fields.music~="0"; settings.sfx=fields.sfx~="0"
    if fields.version~="2" then return settings,p end
    p.money=number("money",40,9999999); p.blanks=number("blanks",3,9999)
    p.drives=math.max(1,number("drives",1,4)); p.completed=number("completed",0,99999)
    local ram=number("ram",512,2048); p.ram=(ram==1024 or ram==2048) and ram or 512
    for _,job in ipairs(Catalog.jobs) do
        p.owned[job.id]=fields["owned_"..job.id]=="1"
        p.delivered[job.id]=number("delivered_"..job.id,0,job.demand)
    end
    if Catalog.get(fields.selected) and p.owned[fields.selected] then p.selected=fields.selected end
    return settings,p
end
function Storage.load()
    -- Guard with getInfo: love.filesystem.read on a missing file hangs the
    -- love.js runtime (worker/proxy deadlock); native LÖVE returns nil either way.
    local data
    if love.filesystem.getInfo("business.dat") then data=love.filesystem.read("business.dat")
    elseif love.filesystem.getInfo("scores.dat") then data=love.filesystem.read("scores.dat") end
    return Storage.decode(data)
end
function Storage.save(settings,p)
    local data=Storage.encode(settings,p)
    local ok,err=love.filesystem.write("business.tmp",data); if not ok then return ok,err end
    local directory=love.filesystem.getSaveDirectory()
    return os.rename(directory.."/business.tmp",directory.."/business.dat")
end
return Storage
