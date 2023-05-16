local TICRATE = TICRATE
local PST_LIVE = PST_LIVE
local k_growshrinktimer = k_growshrinktimer
local k_invincibilitytimer = k_invincibilitytimer
local k_squishedtimer = k_squishedtimer
local k_spinouttimer = k_spinouttimer
local pw_flashing = pw_flashing
local k_hyudorotimer = k_hyudorotimer
local hostmodload = false


local pow_block_shrink = CV_RegisterVar({
	name = "pow_block_shrink",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

addHook("ThinkFrame", do
	if pow_block_shrink.value
		for p in players.iterate
			if not (p.mo and p.mo.valid)
			or p.spectator then continue end
			local ks = p.kartstuff
			if ks[k_growshrinktimer] < 0 
				ks[k_growshrinktimer] = -1
				if not (ks[k_invincibilitytimer] > 0 
				or ks[k_squishedtimer] 
				or ks[k_spinouttimer] 
				or ks[k_hyudorotimer]
				or p.powers[pw_flashing]
				or (HugeQuest and p.hugequest and p.hugequest.huge > 0))
					P_DamageMobj(p.mo)
				end
			end
		end
	end
	if hostmodload or not (server and HOSTMOD and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "Pow Block Shrink", var = "pow_block_shrink"})
	hostmodload = true
end)