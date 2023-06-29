local xitemHooked = false

local VERSION = 1
local FIS_NAMESPACE = "FLOATINGITEMSPAWNER"
local MT_FLOATINGITEMSPAWNER = MT_FLOATINGITEMSPAWNER

local function xitemHandler()
	if xitemHooked then return end
	if not (xItemLib and xItemLib.func) then return end
	local lib = xItemLib.func
	local modData = xItemLib.xItemCrossData.modData
	
	if modData[FIS_NAMESPACE] and modData[FIS_NAMESPACE].defDat.ver <= VERSION then 
		-- Exit early, don't attempt to add this again.
		xitemHooked = true
		return
	end

	lib.addXItemMod(FIS_NAMESPACE, "Floating Item Spawner", 
	{
		lib = "Basically by Spectrum, even if I used ChronoShift's xitem Juicebox fix by JugadorXEI as the base",
		ver = VERSION,
		droppedfunc = function(item, threshold, movecount)
			if not floatingitemspawner or item.spawnedbyspawner then return end
			MT_FLOATINGITEMSPAWNER = $ or _G["MT_FLOATINGITEMSPAWNER"]
			for thing in mapthings.iterate
				local mobj = thing.mobj
				if not (mobj and mobj.valid)
				or mobj.type ~= MT_FLOATINGITEMSPAWNER 
				or mobj.x ~= item.x or mobj.y ~= item.y then continue end
				mobj.spawneditem = item --So the floating item spawner doesn't repeatedly spawn items
				item.spawnedbyspawner = true
				break
			end
			return true
		end
	})

	xitemHooked = true
end

addHook("MapLoad", xitemHandler)
addHook("NetVars", xitemHandler)