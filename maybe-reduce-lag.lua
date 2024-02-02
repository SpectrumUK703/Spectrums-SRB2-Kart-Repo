local addHook_vanilla = addHook
local MF_SCENERY = MF_SCENERY

rawset(_G, "addHook", function(hook, fn, extra)
	if hook == "MobjThinker" and extra == nil
		for i=1, #mobjinfo
			if mobjinfo[i-1] and not (mobjinfo[i-1].flags & MF_SCENERY)
				addHook_vanilla(hook, fn, i-1)
			end
		end
	else
		return addHook_vanilla(hook, fn, extra)
	end
end)