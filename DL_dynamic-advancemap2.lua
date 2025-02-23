local advancemap = CV_FindVar("advancemap")
local val

addHook("MapLoad", function(map)
	advancemap = $ or CV_FindVar("advancemap")
	val = max(P_RandomKey(3)+1,P_RandomKey(3)+1)
	if advancemap.value ~= val
		COM_BufInsertText(server, "advancemap "..tostring(val))
	end
end)