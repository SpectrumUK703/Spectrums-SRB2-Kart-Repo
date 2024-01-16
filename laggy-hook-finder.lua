local addHook_vanilla = addHook

rawset(_G, "addHook", function(hook, fn, extra)
	if hook and string.find(hook, "Mobj") and extra == nil
		print("All objects Mobj hook added!")
	end
	return addHook_vanilla(hook, fn, extra)
end)