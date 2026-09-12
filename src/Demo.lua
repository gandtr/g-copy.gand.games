-- Isolated deterministic visual fixtures; never written to business.dat.
local Demo={}
function Demo.setup(app,mode)
    local g=app.game
    if mode=="classic" then app.page=nil; return end
    if mode=="multi" or mode=="multi_complete" then
        g.profile.drives=4; g.profile.completed=8; g.profile.money=400
        g:buyMaster("castle"); g:setConfig("mode","NIBBLE"); g:setConfig("length","LONG")
        for d=1,3 do g:setDrive("target",d); g:setDrive("target",d) end
        app.page=nil; g:start(); g.faults={}
        for _=1,500 do
            if g.phase=="complete" or (mode=="multi" and g.position>90) then break end
            if g.phase=="swap" then g:loadMedia(g.swapDrive,g.swapMedia) else g:update(0.1,false) end
        end
        return
    end
    if mode=="market" then return end
    if mode=="hardware" then app.marketTab="hardware"; return end
    if mode=="protection" or mode=="retry" then
        g.profile.completed=8; g.profile.money=400
        g:buyMaster(mode=="protection" and "copper" or "paint")
        g:setConfig("first",g.job.first); g:setConfig("last",g.job.last); g:setConfig("side",g.job.side)
    else g:buyMaster("moon") end
    app.page=nil
    if mode=="info" then app.page="info"; return end
    if mode=="range" then app.page="range"; return end
    g:start()
    if mode=="swap" then g:update(10,false)
    elseif mode=="protection" or mode=="retry" then
        for _=1,1000 do
            if g.phase=="blocked" then break end
            if g.phase=="swap" then g:loadMedia(g.swapDrive,g.swapMedia) else g:update(0.1,false) end
        end
        if mode=="retry" then g:retry(); g.repair.elapsed=g.repair.period*0.3 end
    elseif mode=="complete" then
        for _=1,1000 do
            if g.phase=="complete" then break end
            if g.phase=="swap" then g:loadMedia(g.swapDrive,g.swapMedia) else g:update(0.1,false) end
        end
        g:verify(); g:update(5,false)
    else g:update(2,false) end
end
return Demo
