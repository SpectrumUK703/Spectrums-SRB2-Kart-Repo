--Original randommap script by SteelT
--Copied and edited from Ashnal's Utilities v3
--G_BuildMapName(0) picks a map based on cv_newgametype, which is sometimes different from gametype

local GT_RACE = GT_RACE
local TOL_RACE = TOL_RACE
local TOL_MATCH = TOL_MATCH
local LF2_HIDEINMENU = LF2_HIDEINMENU
local P_RandomRange = P_RandomRange
local G_BuildMapNameOriginal = G_BuildMapName --Can you believe this shit works?? lol

local override_randommap = CV_RegisterVar({
	name = "override_randommap",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

rawset(_G, "G_BuildMapName", function(num)
	if num ~= 0 or not override_randommap.value then return G_BuildMapNameOriginal(num) end

	local validmaps = {}
	local validmapcheck
	local tolflags = (gametype == GT_RACE) and TOL_RACE or TOL_MATCH // Battle

	for i=1,#mapheaderinfo // Build validmaps table
		local header = mapheaderinfo[i]
		if not header // Check if the map exist using mapheaderinfo, as there is no way to check for map lump.
		or (header.menuflags & LF2_HIDEINMENU) then // Don't include hell maps
			continue
		end

		if (header.typeoflevel & tolflags) then // Make sure the maps match the current gametype
			table.insert(validmaps, G_BuildMapNameOriginal(i))
			validmapcheck = $ or true
		end
	end

	if validmapcheck then
		return validmaps[P_RandomRange(1, #validmaps)] // Finally pick a random map
	end
	return G_BuildMapNameOriginal(num) --Just in case??
end, 1)