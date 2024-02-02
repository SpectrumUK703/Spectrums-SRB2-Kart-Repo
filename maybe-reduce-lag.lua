local addHook_vanilla = addHook
local MF_SCENERY = MF_SCENERY

rawset(_G, "addHook", function(hook, fn, extra)
	if hook == "MobjThinker" and extra == nil
		for i=0, #mobjinfo
			if mobjinfo[i] and not (mobjinfo[i].flags & MF_SCENERY)
				addHook_vanilla(hook, fn, i)
			end
		end
	else
		return addHook_vanilla(hook, fn, extra)
	end
end)