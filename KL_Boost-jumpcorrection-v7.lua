local k_sneakertimer = k_sneakertimer
local k_speedboost = k_speedboost
local k_boostpower = k_boostpower
local FRACUNIT = FRACUNIT
local TICRATE = TICRATE
local MFE_SPRUNG = MFE_SPRUNG
local hostmodload

local cv_jumpcorrection = CV_RegisterVar({
    name = "jumpcorrection",
    defaultvalue = "On",
    possiblevalue = CV_OnOff,
    flags = CV_NETVAR,
})

-- for stackable panels
local boosttable = {
	{ 53740+768, 75000, 87500},
	{     32768, 49152, 60074},
	{ 17294+768, 32000, 41000}
}

addHook("ThinkFrame", function()
	if not cv_jumpcorrection.value then return end
	local sneakerpower
	local newmomz
	local mo
	local sector
	local special
	local totalboost
	local table
	for p in players.iterate
		p.jumpcorrectiontable = $ or {}
		table = p.jumpcorrectiontable
		sneakerpower = boosttable[gamespeed+1][p.SPSstackedpanels or 1]
		table.springjump = $ and $-1 or 0
		mo = p.mo
		if p.spectator
		or not (mo and mo.valid) then continue end
		sector = P_ThingOnSpecial3DFloor(mo) or mo.subsector.sector
		special = GetSecSpecial(sector.special, 3)
		totalboost = p.kartstuff[k_speedboost]+p.kartstuff[k_boostpower]-FRACUNIT
		if not P_IsObjectOnGround(mo)
			if not table.jumped
			and totalboost > sneakerpower
			and not ((mo.eflags & MFE_SPRUNG) or special == 5 or table.springjump)
				-- In the case of hardsneaker/firmsneaker, this is multiplying by (50%-27.5%/150%)
				newmomz = FixedDiv(FixedMul(-mo.momz, totalboost-sneakerpower), FRACUNIT+totalboost or 1)
				--print(mo.momz)
				--print(p.kartstuff[k_speedboost])
				--print(p.kartstuff[k_boostpower])
				--print(totalboost)
				--print(sneakerpower)
				--print(newmomz)
				P_SetObjectMomZ(mo, newmomz, true)
				--print("Jump corrected")
			end
			table.jumped = true
		else
			table.jumped = false
			if (mo.eflags & MFE_SPRUNG) or special == 5
				table.springjump = 10
			end
		end
	end
	if hostmodload or not (server and HOSTMOD and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "JumpCorrection", var = "jumpcorrection"})
	hostmodload = true
end)

local function springjumpcorrection(mo, pmo)
	if not (cv_jumpcorrection.value 
	and mo and mo.valid and pmo and pmo.valid 
	and pmo.player)
	or pmo.player.spectator
	or abs(mo.z - pmo.z) > max(mo.height, pmo.height) then return end
	local p = pmo.player
	p.jumpcorrectiontable = $ or {}
	local table = p.jumpcorrectiontable
	local sneakerpower = boosttable[gamespeed+1][p.SPSstackedpanels or 1]
	local sector = P_ThingOnSpecial3DFloor(pmo) or pmo.subsector.sector
	local special = GetSecSpecial(sector.special, 3)
	local totalboost = p.kartstuff[k_speedboost]+p.kartstuff[k_boostpower]-FRACUNIT
	if not table.jumped
	and totalboost > sneakerpower
	and not ((pmo.eflags & MFE_SPRUNG) or special == 5 or table.springjump)
		local newspeed = p.speed - FixedDiv(FixedMul(p.speed, totalboost-sneakerpower), FRACUNIT+totalboost or 1)
		p.speed = newspeed
		table.jumped = true
		table.springjump = 10
	end
end

addHook("MobjCollide", springjumpcorrection, MT_REDDIAG)
addHook("MobjCollide", springjumpcorrection, MT_YELLOWDIAG)
addHook("MobjCollide", springjumpcorrection, MT_BLUEDIAG)
freeslot("MT_GRAYDIAG")
freeslot("MT_22_REDDIAG")
freeslot("MT_22_YELDIAG")
freeslot("MT_22_BLUDIAG")
addHook("MobjCollide", springjumpcorrection, MT_GRAYDIAG)
addHook("MobjCollide", springjumpcorrection, MT_22_REDDIAG)
addHook("MobjCollide", springjumpcorrection, MT_22_YELDIAG)
addHook("MobjCollide", springjumpcorrection, MT_22_BLUDIAG)
