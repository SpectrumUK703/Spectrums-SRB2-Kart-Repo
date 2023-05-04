if not (xItemLib and tsrb2kr) then return end

local xItem_FindHudFlags_Original = xItemLib.func.hudFindFlags

local function xItem_FindHudFlags_Edit(v, p, c)
	if not G_RaceGametype() then return xItem_FindHudFlags_Original(v, p, c) end
	local x, y = 265, 5
	if (splitscreen)
		x, y = 270, -1
		if ((splitscreen) > 1)
			x, y = 121, -8
		end
	end
	local flags = tsrb2kr.ReturnSplitFlags(V_SNAPTORIGHT|V_SNAPTOTOP|V_HUDTRANS, tsrb2kr.IsDisplayPlayer(p))
	return x, y, flags
end

xItemLib.func.hudFindFlags = xItem_FindHudFlags_Edit