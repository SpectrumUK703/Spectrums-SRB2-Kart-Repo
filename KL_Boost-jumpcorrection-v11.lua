local k_sneakertimer = k_sneakertimer
local k_speedboost = k_speedboost
local k_boostpower = k_boostpower
local FRACUNIT = FRACUNIT
local TICRATE = TICRATE
local MFE_SPRUNG = MFE_SPRUNG
local MF_SPRING = MF_SPRING
local k_pogospring = k_pogospring
local MF2_OBJECTFLIP = MF2_OBJECTFLIP
local hostmodload

local cv_jumpcorrection = CV_RegisterVar({
    name = "jumpcorrection",
    defaultvalue = "On",
    possiblevalue = CV_OnOff,
    flags = CV_NETVAR,
})

local jumpcorrection_debug = CV_RegisterVar({
    name = "jumpcorrection-debug",
    defaultvalue = "Off",
    possiblevalue = CV_OnOff,
    flags = 0,
})

-- for stackable panels
local boosttable = {
	{ 53740+768, 75000, 87500},
	{     32768, 49152, 60074},
	{     21319, 32000, 41000}	-- 21319 is the average of 17294+768 (sneaker speed on Hard) and 24576 (invincibility speed)
}

addHook("ThinkFrame", function()
	if not cv_jumpcorrection.value
	or mapobjectscale < FRACUNIT then return end	-- it gets weird
	local normalboostpower
	local newspeed
	local newmomz
	local mo
	local sector
	local dash
	local bouncy
	local fuckingmushroom -- mushroom plunge lmao
	local totalboost
	local table
	local isrising
	for p in players.iterate
		p.jumpcorrectiontable = $ or {}
		table = p.jumpcorrectiontable
		normalboostpower = boosttable[gamespeed+1][p.SPSstackedpanels or 1]
		table.speedboost = p.kartstuff[k_speedboost]
		table.boostpower = p.kartstuff[k_boostpower]
		table.springjump = $ and $-1 or 0
		mo = p.mo
		if p.spectator
		or not (mo and mo.valid) then continue end
		sector = P_ThingOnSpecial3DFloor(mo) or mo.subsector.sector
		dash = GetSecSpecial(sector.special, 3) == 5
		bouncy = GetSecSpecial(sector.special, 1) == 15
		fuckingmushroom = GetSecSpecial(sector.special, 2)
		totalboost = table.speedboost+table.boostpower
		isrising = mo.momz*P_MobjFlip(mo) > 0
		if not P_IsObjectOnGround(mo)
			if not table.jumped
			and totalboost > normalboostpower+FRACUNIT and isrising
			and not ((mo.eflags & MFE_SPRUNG) or p.kartstuff[k_pogospring] or dash or bouncy or fuckingmushroom == 4 or fuckingmushroom == 5 or table.springjump)
				-- In the case of hardsneaker/firmsneaker, this is multiplying by (127.5%/150%) for z movement
				newspeed = FixedDiv(FixedMul(p.speed, FRACUNIT+normalboostpower), totalboost or 1)
				newmomz = FixedDiv(FixedMul(mo.momz, FRACUNIT+normalboostpower), totalboost or 1)
				if jumpcorrection_debug.value
					print("p.speed: "..p.speed)
					print("mo.momz: "..mo.momz)
					print("k_speedboost: "..table.speedboost)
					print("k_boostpower: "..table.boostpower)
					print("totalboost: "..totalboost)
					print("normalboostpower: "..normalboostpower)
					print("newspeed: "..newspeed)
					print("newmomz: "..newmomz)
					print("Jump corrected")
				end
				P_InstaThrust(mo, R_PointToAngle2(0, 0, mo.momx, mo.momy), newspeed)
				P_SetObjectMomZ(mo, newmomz, false)
			end
			table.jumped = true
		else
			table.jumped = false
			if (mo.eflags & MFE_SPRUNG) or p.kartstuff[k_pogospring] or dash or bouncy or fuckingmushroom == 4 or fuckingmushroom == 5
				table.springjump = 10
			end
		end
	end
	if hostmodload or not (server and HOSTMOD and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "JumpCorrection", var = "jumpcorrection"})
	hostmodload = true
end)

local function springjumpcorrection(pmo, mo)
	if not (cv_jumpcorrection.value 
	and mo and mo.valid and pmo and pmo.valid and mo.health and pmo.health 
	and pmo.player and (mo.flags & MF_SPRING))
	or mapobjectscale < FRACUNIT	-- it gets weird
	or pmo.player.spectator
	or abs(mo.z - pmo.z) > max(mo.height, pmo.height) then return end
	local p = pmo.player
	p.jumpcorrectiontable = $ or {}
	local table = p.jumpcorrectiontable
	local normalboostpower = boosttable[gamespeed+1][p.SPSstackedpanels or 1]
	local sector = P_ThingOnSpecial3DFloor(pmo) or pmo.subsector.sector
	local dash = GetSecSpecial(sector.special, 3) == 5
	local bouncy = GetSecSpecial(sector.special, 1) == 15
	local fuckingmushroom = GetSecSpecial(sector.special, 2)
	local totalboost = table.speedboost+table.boostpower
	if not table.jumped
	and totalboost > normalboostpower+FRACUNIT
	and not ((pmo.eflags & MFE_SPRUNG) or p.kartstuff[k_pogospring] or dash or bouncy or fuckingmushroom == 4 or fuckingmushroom == 5 or table.springjump)
		local newspeed = FixedDiv(FixedMul(p.speed, FRACUNIT+normalboostpower), totalboost or 1)
		if jumpcorrection_debug.value
			print("p.speed: "..p.speed)
			print("k_speedboost: "..table.speedboost)
			print("k_boostpower: "..table.boostpower)
			print("totalboost: "..totalboost)
			print("normalboostpower: "..normalboostpower)
			print("newspeed: "..newspeed)
			print("Spring jump corrected")
		end
		p.speed = newspeed
		table.jumped = true
		table.springjump = 10
		return true
	end
end

addHook("MobjMoveCollide", springjumpcorrection, MT_PLAYER)
addHook("MobjCollide", springjumpcorrection, MT_PLAYER)
