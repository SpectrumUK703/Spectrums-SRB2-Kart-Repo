

--local MAP_ID= "PY"

local RESTORE_TIME= 300*TICRATE

local CV_TO_CHANGE={
    {cvname="hq_superform", value= "off", map= "PY"},
    {cvname="kartfrantic", value= "on", map= "PY"},
    {cvname="karteliminatelast", value= "off", map= "ZL"},
    {cvname="kmp_slowspinout", value= "off", map= "FN"},
    {cvname="fd_hitkill", value= "off", map= "FN"},
}






local function getMapID(n)
    if n<100 then
        return (n<10) and ("0"..n) or tostring(n)
    end

    local x= n-100
    local p= x/36
    local q= x-(36*p)
    local a= string.char(string.byte('A')+p)
    local b= (q<10) and tostring(q) or string.char(string.byte('A')+q-10)

    return a..b
end



local CV_Backups= nil

local function backupAndChangeCV()
    /*if not CV_Backups then
        CV_Backups= {}
    end*/

    local ID = getMapID(gamemap) 

    for i=1,#CV_TO_CHANGE do
        local obj= CV_TO_CHANGE[i]
        if ID ~= obj.map then continue end
        local cv= CV_FindVar(obj.cvname)
        if not cv then
            print("ERROR - Counldn't access CVar '"..obj.cvname.."'...")
            continue
        end

        CV_Backups = $ or {}
        CV_Backups[obj.cvname]= cv.value

        COM_BufInsertText(server,obj.cvname.." "..obj.value)
    end
end

local function restoreCV()
    if not CV_Backups then return end

    for cvname,value in pairs(CV_Backups) do
        local cv= CV_FindVar(cvname)
        if not cv then
            print("ERROR - Counldn't restore CVar '"..cvname.."'...")
            continue
        end

        COM_BufInsertText(server,cvname.." "..value)
    end

    CV_Backups= nil
end


addHook("ThinkFrame", function()
    if leveltime==0 then
        restoreCV()
    end
    
    --if getMapID(gamemap)==MAP_ID then
        if leveltime==10 then
            backupAndChangeCV()
        end
        if leveltime==RESTORE_TIME then
            restoreCV()
        end
    --end
end)

addHook("IntermissionThinker", restoreCV)
addHook("VoteThinker", restoreCV)
