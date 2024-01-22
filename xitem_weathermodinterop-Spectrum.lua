local xitemHooked = false

local VERSION = 1
local WEATHER_NAMESPACE = "WEATHERMOD"

local function xitemHandler()
	if xitemHooked then return end
	if not weathermod then return end
	if not (xItemLib and xItemLib.func) then return end
	local lib = xItemLib.func
	local modData = xItemLib.xItemCrossData.modData
	
	if modData[WEATHER_NAMESPACE] and modData[WEATHER_NAMESPACE].defDat.ver > VERSION then 
		-- Exit early, don't attempt to add this again.
		xitemHooked = true
		return
	end

	lib.addXItemMod(WEATHER_NAMESPACE, "Weathermod", 
	{
		lib = "By Titou - XItem interop by Spectrum, modified from JugadorXEI's interop for various mods",
		ver = VERSION,
		-- Fixes Mountain vapor weather in Weathermod
		preplayerthink = function(player)
			if not (player and player.xItemData) then return end
			if not (weathermod.active == true and cv_weathermod.value) then
				player.xItemData.enableHud = true
				return
			end
			if (weathermod.current.id == 14 or (weathermod.current.id == 95 and weathermod.Disasterpick.effect == 5)) and replayplayback == false
				player.xItemData.enableHud = false
				if JUICEBOX and JUICEBOX.value
					player.gatedecay = 0
				end
			else
				player.xItemData.enableHud = true
			end
		end
	})

	xitemHooked = true
end

addHook("MapLoad", xitemHandler)
addHook("NetVars", xitemHandler)