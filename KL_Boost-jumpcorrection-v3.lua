local k_sneakertimer = k_sneakertimer
local k_speedboost = k_speedboost
local FRACUNIT = FRACUNIT
local TICRATE = TICRATE
local MFE_SPRUNG = MFE_SPRUNG
local cv_kartspeed = CV_FindVar("kartspeed")
local hostmodload

local cv_jumpcorrection = CV_RegisterVar({
    name = "jumpcorrection",
    defaultvalue = "On",
    possiblevalue = CV_OnOff,
    flags = CV_NETVAR,
})

local sneakerpowertable = {53740+768, 32768, 17294+768}

addHook("ThinkFrame", function()
	if not cv_jumpcorrection.value then return end
	cv_kartspeed = $ or CV_FindVar("kartspeed")
	local sneakerpower = sneakerpowertable[cv_kartspeed.value+1]
	for p in players.iterate
		p.springjump = $ and $-1 or 0
		local mo = p.mo
		if p.spectator
		or not (mo and mo.valid) then continue end
		local sector = mo.subsector.sector
		local special = GetSecSpecial(sector.special, 3)
		if not P_IsObjectOnGround(mo)
			if not p.jumped
			and p.kartstuff[k_speedboost] > sneakerpower
			and not ((mo.eflags & MFE_SPRUNG) or special == 5 or p.springjump)
				-- In the case of hardsneaker/firmsneaker, this is (50%-27.5%/150%)
				--print(-mo.momz*((p.kartstuff[k_speedboost]-sneakerpower)/16)/((FRACUNIT+p.kartstuff[k_speedboost])/16))
				P_SetObjectMomZ(mo, -mo.momz*((p.kartstuff[k_speedboost]-sneakerpower)/16)/((FRACUNIT+p.kartstuff[k_speedboost])/16), true)
				--print("Jump corrected")
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
	HM_Scoreboard_AddMod({disp = "JumpCorrection", var = "jumpcorrection"})
	hostmodload = true
end)
