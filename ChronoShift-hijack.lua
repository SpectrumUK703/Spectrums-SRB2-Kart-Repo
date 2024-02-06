local addHook_vanilla = addHook
local MF_SCENERY = MF_SCENERY
local hijackdone = false

rawset(_G, "addHook", function(hook, fn, extra)
	if not hijackdone and hook == "TouchSpecial" and extra == nil
		addHook_vanilla(hook, fn, MT_EGGMANITEM)
		addHook_vanilla(hook, fn, MT_EGGMANITEM_SHIELD)
		print("hijack complete!")
		hijackdone = true
	else
		return addHook_vanilla(hook, fn, extra)
	end
end)