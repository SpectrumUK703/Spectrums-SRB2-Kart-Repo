local TICRATE = TICRATE
local MF2_ALREADYHIT = MF2_ALREADYHIT
local KITEM_FLAMESHIELD = KITEM_FLAMESHIELD
local KSHIELD_TOP = KSHIELD_TOP
local MT_PLAYER = MT_PLAYER
local abs = abs
local searchBlockmap = searchBlockmap
local S_StartSound = S_StartSound
local pairs = pairs
freeslot("sfx_graze")

local itemgrazing = CV_RegisterVar({
	name = "itemgrazing",
	defaultvalue = "On",
	possibleValue = CV_OnOff,
	flags = CV_NETVAR,
	description = "Allows players to graze on opponents' attacking items for a speed boost."
})

local itemtable = {
	[MT_SSMINE_SHIELD] = true,
	[MT_ORBINAUT] = true,
	[MT_ORBINAUT_SHIELD] = true,
	[MT_JAWZ_SHIELD] = true,
	[MT_BANANA] = true,
	[MT_BANANA_SHIELD] = true,
	[MT_LANDMINE] = true,
	[MT_BALLHOG] = true,
	[MT_GARDENTOP] = true,
	[MT_GACHABOM] = true,
	[MT_INSTAWHIP] = true,
	[MT_SUPER_FLICKY] = true,
	[MT_DROPTARGET] = true,
	[MT_DROPTARGET_SHIELD] = true,
	[MT_SPBEXPLOSION] = true,
	[MT_PLAYER] = true,
}

local function isplayerhazardous(p)
	return (p.invincibilitytimer or (p.growshrinktimer and p.growshrinktimer > 0)
	or (p.flamedash and p.itemtype and p.itemtype == KITEM_FLAMESHIELD)
	or p.bubbleblowup)
end

local function blockmapsearchfunc(pmo, mo)
	if mo == pmo
	or mo.target == pmo
	or (mo.player and mo.player.valid and not isplayerhazardous(mo.player)) then return end
	if itemtable[mo.type]
	and R_PointToDist2(pmo.x, pmo.y, mo.x, mo.y) <= 2*(pmo.radius + mo.radius)
	and abs(pmo.z - mo.z) <= (pmo.height + mo.height)	-- Pretty close in height too
		mo.grazedtable = $ or {}
		if not mo.grazedtable[#pmo.player]
			mo.grazedtable[#pmo.player] = true
			S_StartSound(nil, sfx_graze, pmo.player)
			pmo.player.driftboost = $+TICRATE
		else
			pmo.player.driftboost = $+1
		end
	end
end

local mo
local hostmod
addHook("ThinkFrame", function()
	if not hostmod and HM_Scoreboard_AddMod --check for hostmod every frame, see if scoreboard is on.
		HM_Scoreboard_AddMod({disp = "Grazing", var = "itemgrazing"}) --hostmod manages displaying/hiding this for us.
		hostmod = true
	end
	if not itemgrazing.value then return end
	if leveltime <= starttime then return end
	-- This was originally a MT_PLAYER MobjThinker lol
	for p in players.iterate
		mo = p.mo
		if not (mo and mo.valid) then continue end
		if not mo.health or mo.hitlag or (mo.flags2 & MF2_ALREADYHIT) then continue end
		if not isplayerhazardous(p)
			if not (p.exiting or p.spectator or p.flashing or p.spinouttimer or p.hyudorotimer or p.curshield == KSHIELD_TOP)
				searchBlockmap("objects", blockmapsearchfunc, mo)
			end
			mo.grazedtable = {}
		end
	end
end)

addHook("MapLoad", function()
	for p in players.iterate
		if p.mo and p.mo.valid
			p.mo.grazedtable = {}
		end
	end
end)