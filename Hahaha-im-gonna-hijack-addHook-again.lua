local addHook_vanilla = addHook
local hijacked

rawset(_G, "addHook", function(hook, func, motype)
	if hijacked then
		return addHook_vanilla(hook, func, motype)
	end
	if hook == "MobjDamage" and motype == nil	-- Fairly sure the function should only be running for MT_PLAYER
		hijacked = true
		print("all objects MobjDamage hook changed to only run for MT_PLAYER")
		return addHook_vanilla(hook, func, MT_PLAYER)
	else
		return addHook_vanilla(hook, func, motype)
	end
end)