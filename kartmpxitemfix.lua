-- KartMP is reusable, yay

local TICRATE = TICRATE
local MF2_DONTDRAW = MF2_DONTDRAW

if not MT_FLOATINGXITEM
	freeslot("MT_FLOATINGXITEM")
end

local xitemHooked = false

local VERSION = 1
local KMP_NAMESPACE = "FLOATINGITEMFUSE"

local function xitemHandler()
	if xitemHooked then return end
	if not (xItemLib and xItemLib.func) then return end
	local lib = xItemLib.func
	local modData = xItemLib.xItemCrossData.modData
	
	if modData[KMP_NAMESPACE] and modData[KMP_NAMESPACE].defDat.ver <= VERSION then 
		-- Exit early, don't attempt to add this again.
		xitemHooked = true
		return
	end

	lib.addXItemMod(KMP_NAMESPACE, "Floating Item Fuse", 
	{
		lib = "*shrug*",
		ver = VERSION,
		droppedfunc = function(mo, threshold, movecount)
			-- Copied and edited from KartMP
			-- make floating items despawn after a while, determined by lap count.
			-- credits to Steel Titanium for the original script

			if not (kmp and kmp_floatingitemfuse.value) return end

			if P_IsObjectOnGround(mo) and (not mo.fuse)

				local numlaps = mapheaderinfo[gamemap].numlaps
				mo.fuse = max(12*TICRATE, (60-(10*numlaps))*TICRATE)
			end

			if mo.fuse then
				mo.flags2 = (mo.fuse <= 5*TICRATE and leveltime % 2) and $ + MF2_DONTDRAW or $ & ~(MF2_DONTDRAW)
			end
		end
	})

	xitemHooked = true
end

addHook("MapLoad", xitemHandler)
addHook("NetVars", xitemHandler)

addHook("MobjFuse", function(mo)
	P_RemoveMobj(mo)
end, MT_FLOATINGXITEM)
