local SLIPTIDEHANDLING = FRACUNIT/2
local function HugeQuest(mo)
	if not (mo and mo.valid) then return end
	local p = mo.player
	
	if p.growshrinktimer > 0 then
		if not p.growfromlasers	-- it made Shrink too powerful
			--print("Hugequest")
			p.offroad = 0
			p.speedboost = max($, FRACUNIT/10)
			p.accelboost = max($, 3*FRACUNIT/2)
			p.handleboost = max($, SLIPTIDEHANDLING)
			p.boostpower = max($, FRACUNIT)
		end
	else
		p.growfromlasers = nil
	end
end
addHook("MobjThinker", HugeQuest, MT_PLAYER)

local function touchgrowshrinklasers(mo, mo2)
	if mo2 and mo2.valid and mo and mo.valid and mo.player and mo.player.valid
	and mo2.z + mo2.height >= mo.z
	and mo2.z <= mo.z + mo.height
	and (mo2.type == MT_SHRINK_GUN or mo2.type == MT_SHRINK_PARTICLE)
		mo.player.growfromlasers = true	-- If we're not the owner of it, the other function will immediately set this to nil anyway
	end
end

addHook("MobjCollide", touchgrowshrinklasers, MT_PLAYER)
addHook("MobjMoveCollide", touchgrowshrinklasers, MT_PLAYER)
