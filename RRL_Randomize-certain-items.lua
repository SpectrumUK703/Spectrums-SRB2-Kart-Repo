local commandstorandomize = {
	"gardentop ",
	"shrink ",
	"grow "
}

local varsrandomized = false

addHook("IntermissionThinker", function()
	if varsrandomized then return end
	for k, v in pairs(commandstorandomize)
		COM_BufInsertText(server, v..tostring(P_RandomChance(FRACUNIT/2)))
	end
	varsrandomized = true
end)

addHook("MapLoad", function(map)
	varsrandomized = false
end)

--Probably not that important to NetVar it
addHook("NetVars", function(net)
	varsrandomized = net($)
end)