if not xItemLib then return end

local BASEVIDWIDTH  = 320
local BASEVIDHEIGHT = 200

local ITEM_X = 5
local ITEM_Y = 5

local ITEM1_X = -9
local ITEM1_Y = -8

local ITEM2_X = BASEVIDWIDTH-39
local ITEM2_Y = -8
local colormode = TC_RAINBOW
local localcolor = SKINCOLOR_NONE
local V_SNAPTOTOP = V_SNAPTOTOP
local V_SNAPTOLEFT = V_SNAPTOLEFT
local V_SNAPTORIGHT = V_SNAPTORIGHT
local V_SPLITSCREEN = V_SPLITSCREEN
local V_HUDTRANS = V_HUDTRANS

local function xItem_FindHudFlags_Original(v, p, c)
	if splitscreen < 2 then -- don't change shit for THIS splitscreen.
		if c.pnum == 1 then
			return ITEM_X, ITEM_Y, V_SNAPTOTOP|V_SNAPTOLEFT, false
		else
			return ITEM_X, ITEM_Y, V_SNAPTOLEFT|V_SPLITSCREEN, false
		end
	else -- now we're having a fun game.
		if c.pnum == 1 or c.pnum == 3 then -- If we are P1 or P3...
			return ITEM1_X, ITEM1_Y, (c.pnum == 3 and V_SPLITSCREEN or V_SNAPTOTOP)|V_SNAPTOLEFT, false	-- flip P3 to the bottom.	
		else -- else, that means we're P2 or P4.
			return ITEM2_X, ITEM2_Y, (c.pnum == 4 and V_SPLITSCREEN or V_SNAPTOTOP)|V_SNAPTORIGHT, true
		end
	end
end

local function xItem_FindHudFlags_Edit(v, p, c)
	if not (tsrb2kr and G_RaceGametype()) 
		return xItem_FindHudFlags_Original(v, p, c)
	end
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