local xitemHooked = false

local VERSION = 3
local FIS_NAMESPACE = "FLOATINGITEMSPAWNER"

if not MT_FLOATINGITEMSPAWNER
	freeslot("MT_FLOATINGITEMSPAWNER")
end

local floatingitemspawnertable = {}

addHook("NetVars", function(net)
	floatingitemspawnertable = net($)
end)

addHook("MobjSpawn", function(mo)
	floatingitemspawnertable[mo.x] = $ or {}
	floatingitemspawnertable[mo.x][mo.y] = $ or {}
	table.insert(floatingitemspawnertable[mo.x][mo.y], mo)
end, MT_FLOATINGITEMSPAWNER)

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
			if not floatingitemspawner or item.spawnedbyspawner
			or not (floatingitemspawnertable[item.x] and floatingitemspawnertable[item.x][item.y]) then return end
			for i=1, #floatingitemspawnertable[item.x][item.y]
				local mobj = floatingitemspawnertable[item.x][item.y][i]
				if not (mobj and mobj.valid)
				or (mobj.spawneditem and mobj.spawneditem.valid) then continue end
				mobj.spawneditem = item
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