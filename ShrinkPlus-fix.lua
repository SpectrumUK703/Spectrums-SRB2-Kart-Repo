--Missing ( moment

local k_growshrinktimer = k_growshrinktimer

local smol = {MT_BANANA, MT_BANANA_SHIELD, MT_ORBINAUT, MT_ORBINAUT_SHIELD, MT_JAWZ, MT_JAWZ_SHIELD, MT_JAWZ_DUD, MT_SSMINE, MT_SSMINE_SHIELD, MT_BALLHOG, MT_SINK}
for _,i in ipairs(smol) do
	addHook("MobjThinker", function(mo)
		if (HugeQuest and hq_huge.value) or (not (mo and mo.valid)) then return end
		
		if (mo.target and mo.target.valid) and (mo.target.player and mo.target.player.valid) then -- fear	
			if (mo.target.player.kartstuff[k_growshrinktimer] < 0) then
				mo.destscale = mo.target.scale
				mo.scalespeed = 1
			end
		end
	end, i)
end