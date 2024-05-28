local SLIPTIDEHANDLING = FRACUNIT/2
local function HugeQuest(mo)
	if not (mo and mo.valid) then return end
	local p = mo.player
	
	if p.growshrinktimer > 0 and not p.roundconditions.consecutive_grow_lasers then	-- it made Shrink too powerful
		p.offroad = 0
		p.speedboost = max($, FRACUNIT/10)
		p.accelboost = max($, 3*FRACUNIT/2)
		p.handleboost = max($, SLIPTIDEHANDLING)
		p.boostpower = max($, FRACUNIT)
	end
end
addHook("MobjThinker", HugeQuest, MT_PLAYER)