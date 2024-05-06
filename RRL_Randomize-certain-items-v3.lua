local commandstorandomize = {
	"gardentop",
	--"shrink",
	"grow"
}

local varsrandomized = false

addHook("IntermissionThinker", function()
	if varsrandomized then return end
	varsrandomized = true
	for k, v in ipairs(commandstorandomize)
		if P_RandomChance(FRACUNIT/2)
			if not CV_FindVar(v).value
				print(v.." is now enabled.")
				COM_BufInsertText(server, v.." on")
			end
		elseif CV_FindVar(v).value
			print(v.." is now disabled.")
			COM_BufInsertText(server, v.." off")
		end
	end
end)

addHook("MapLoad", function(map)
	varsrandomized = false
end)

addHook("NetVars", function(net)
	varsrandomized = net($)
end)