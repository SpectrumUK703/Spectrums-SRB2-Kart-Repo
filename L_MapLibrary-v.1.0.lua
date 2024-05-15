local tol_typenames = { "TOL_Singleplayer", "TOL_CO-OP", "TOL_Competition", "TOL_Race", "TOL_Tag", "TOL_Match", "TOL_CTF", "TOL_NIghts", "TOL_Custom" }
local tol_types = { TOL_SP, TOL_COOP, TOL_COMPETITION, TOL_RACE, TOL_TAG, TOL_MATCH, TOL_CTF, TOL_NIGHTS, TOL_CUSTOM }
-- Agian, collab with Gould :v

local function printtols(i) --  Check for the actual TOLS, since they return as an stored int. if you try to get it. - Libra
local s = ""
    for j = 1,#tol_types do
        if mapheaderinfo[i].typeoflevel & tol_types[j] then
            s = s + tol_typenames[j] + ", "
        end
    end
    print("Type of Level : " + s)
end

local function MapCutscn(i) -- Checks if map has a Cutscene or Pre-cutscene num.
    local maphasCutscn = false -- Statement set
            if mapheaderinfo[i].precutscenenum or mapheaderinfo[i].cutscenenum then
                maphasCutscn = true -- Return true for the statement.
            end
            print("Map has Cutscene/Pre-cutscene : " + (hasCutscene and "Yes" or "No"))
        end

-- Map Library

COM_AddCommand("maplibrary", function(player)
    for i = 1,#mapheaderinfo do -- i will iterate all maps existing, it doesnt cause an infinite loop apperantly - Libra
        if mapheaderinfo[i] then
            print("Map Number : " + G_BuildMapName(i))
            print("Map Title : " + G_BuildMapTitle(i))
            print("Next Map : " + mapheaderinfo[i].nextlevel)
            if not (mapheaderinfo[i].keywords == (nil or "")) then
            print("Keywords : " + mapheaderinfo[i].keywords)
            printtols(i) -- Doing this is tricky, if we want to get the real tols, we should do a func for - Gould
            MapCutscn(i)
            S_StartSound(nil, sfx_menu1, player)
        end
    end
   end
  end, COM_LOCAL) -- dont make it sync-depending, since its only used to print all maps

-- Find Map

COM_AddCommand("findmap",function(player, argument)
    if not argument then 
        -- first, we need to do this here
        -- since this is as early as we can check this, and we want to get rid of this case.
        print("Find specific maps from maplibrary")
        print("e.g. findmap 01 will Return GFZ1/Greenflower Zone Act 1")
            S_StartSound(nil, sfx_menu1, player)
        return
    end

    local i, title = G_FindMap(argument)
    if title then
        -- we'll clean this later
        print("Map Number : " + G_BuildMapName(i))
        print("Map Title : " + G_BuildMapTitle(i))
        print("Next Map : " + mapheaderinfo[i].nextlevel)
            if not (mapheaderinfo[i].keywords == (nil or "")) then
        print("Keywords : " + mapheaderinfo[i].keywords)
        printtols(i)
        S_StartSound(nil, sfx_menu1, player)
        return
        end
    end

    local mapnum = tonumber(argument)
    if mapnum ~= nil and (mapnum < 1 or mapnum >= #mapheaderinfo) then
	    print("Map " + argument + " does not exist!")
        S_StartSound(nil, sfx_menu1, player)
	    return
    end
    
    -- since this function returns the same in all iterations, we only need to check it once
    local i, title = G_FindMapByNameOrCode(argument)
    if title then
        -- we'll clean this later
        print("Map Number : " + G_BuildMapName(i))
        print("Map Title : " + G_BuildMapTitle(i))
        print("Next Map : " + mapheaderinfo[i].nextlevel)
        if not (mapheaderinfo[i].keywords == (nil or "")) then
        print("Keywords : " + mapheaderinfo[i].keywords)
        printtols(i)
        MapCutscn(i)
        S_StartSound(nil, sfx_menu1, player)
        return
        end
    end
    
    -- place this after the loop, so we don't spam this as we iterate each map
    print("Map " + argument + " does not exist!")
    S_StartSound(nil, sfx_menu1, player)
end, COM_LOCAL)