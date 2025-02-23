addHook("MapLoad", function(map)
	COM_BufInsertText(server, "advancemap "..tostring(max(P_RandomKey(3)+1,P_RandomKey(3)+1)))
end)