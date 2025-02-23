local advancemap = CV_FindVar("advancemap")
local FRACUNIT = FRACUNIT

addHook("MapLoad", function(map)
	advancemap = $ or CV_FindVar("advancemap")
	if P_RandomChance(FRACUNIT/2)	-- 50% chance
		if advancemap.value ~= 3	 -- Vote
			COM_BufInsertText(server, "advancemap 3")
		end
	elseif P_RandomChance(FRACUNIT/2)	-- 25% chance
		if advancemap.value ~= 2	-- Random
			COM_BufInsertText(server, "advancemap 2")
		end
	else
		if advancemap.value ~= 1	-- Next
			COM_BufInsertText(server, "advancemap 1")
		end
	end
end)