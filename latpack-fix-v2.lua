local MF2_DONTDRAW = MF2_DONTDRAW
local k_spinouttimer = k_spinouttimer

addHook("MobjThinker", function(mo)
	if not ((HugeQuest or tsrb2kr) and mo.ggz_frozen) then return end
	local p = mo.player
	if not (p and p.valid and ((p.huge and p.huge > 0) or (p.hugequest and p.hugequest.huge and p.hugequest.huge > 0) or mo.tsr_ultimateon)) then return end
	mo.ggz_frozen = nil
	p.kartstuff[k_spinouttimer] = 0
	mo.flags2 = $ & ~MF2_DONTDRAW
	mo.ggz_mashready = nil
	mo.ggz_wiggle = 0
	mo.ggz_mashtimer = 0
	mo.ggz_shaketime = 0
	mo.ggz_frozentimer = 0
	K_DoInstashield(p)
end, MT_PLAYER)
