local k_sneakertimer = k_sneakertimer
local k_speedboost = k_speedboost
local FRACUNIT = FRACUNIT
local TICRATE = TICRATE
local MFE_SPRUNG = MFE_SPRUNG
local cv_kartspeed = CV_FindVar("kartspeed")
local hostmodload

addHook("ThinkFrame", function()
	if not kmp then return end
	if JUICEBOX and JUICEBOX.value and not kmp_hardsneakers.value and leveltime > TICRATE
		COM_BufInsertText(server, "kmp_hardsneakers on") --override Juicebox, we'll correct the jumps
		return
	end
	if not kmp_hardsneakers.value then return end
	cv_kartspeed = $ or CV_FindVar("kartspeed")
	if cv_kartspeed.value ~= 2 then return end
	for p in players.iterate
		p.springjump = $ and $-1 or 0
		local mo = p.mo
		if p.spectator
		or not (mo and mo.valid) then continue end
		local sector = mo.subsector.sector
		local special = GetSecSpecial(sector.special, 3)
		if not P_IsObjectOnGround(mo)
			if not p.jumped
			and p.kartstuff[k_sneakertimer]
			and not ((mo.eflags & MFE_SPRUNG) or special == 5 or p.springjump)
				P_SetObjectMomZ(mo, -mo.momz*3/20, true)
			end
			p.jumped = true
		else
			p.jumped = false
			if (mo.eflags & MFE_SPRUNG) or special == 5
				p.springjump = 10
			end
		end
	end
	if hostmodload or not (server and HOSTMOD and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "JumpCorrection", var = "kmp_hardsneakers"})
	hostmodload = true
end)

addHook("IntermissionThinker", function()
	if not (kmp and JUICEBOX and JUICEBOX.value and kmp_hardsneakers.value) then return end
	COM_BufInsertText(server, "kmp_hardsneakers off") --To avoid Juicebox spamming the console
end)