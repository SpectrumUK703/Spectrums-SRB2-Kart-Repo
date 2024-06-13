local TICRATE = TICRATE
local MF2_ALREADYHIT = MF2_ALREADYHIT
local KITEM_FLAMESHIELD = KITEM_FLAMESHIELD
local MT_PLAYER = MT_PLAYER
local KSHIELD_TOP = KSHIELD_TOP
freeslot("sfx_graze")
local itemtable = {
	[MT_SSMINE_SHIELD] = true,
	[MT_ORBINAUT] = true,
	[MT_ORBINAUT_SHIELD] = true,
	[MT_JAWZ] = true,
	[MT_JAWZ_SHIELD] = true,
	[MT_BANANA] = true,
	[MT_BANANA_SHIELD] = true,
	[MT_LANDMINE] = true,
	[MT_BALLHOG] = true,
	[MT_GARDENTOP] = true,
	[MT_GACHABOM] = true,
	[MT_INSTAWHIP] = true,
	[MT_SPB] = true,
	[MT_SUPER_FLICKY] = true,
	[MT_DROPTARGET] = true,
	[MT_DROPTARGET_SHIELD] = true,
}

local function isplayerhazardous(p)
	return (p and p.valid 
	and (p.invincibilitytimer or p.growshrinktimer > 0
	or (p.flamedash and p.itemtype == KITEM_FLAMESHIELD)
	or p.bubbleblowup))
end

local function blockmapsearchfunc(pmo, mo)
	if pmo and pmo.valid and pmo.player and pmo.player.valid and mo and mo.valid and mo.type 
	and (itemtable[mo.type] or (mo.type == MT_PLAYER and isplayerhazardous(mo.player)))
	and abs(pmo.z - mo.z) <= pmo.height + mo.height	-- Pretty close in height too
	and not ((mo.target and mo.target == pmo) or (mo == pmo))
		mo.grazetable = $ or {}
		mo.grazetable[#pmo.player+1] = $ and $+1 or 1
		if mo.grazetable[#pmo.player+1] < TICRATE
			pmo.player.grazesthistic = $+1
		else
			mo.grazetable[#pmo.player+1] = TICRATE
		end
	end
end

addHook("MobjThinker", function(mo)
	if not (mo and mo.valid and mo.health) or mo.hitlag or (mo.flags2 & MF2_ALREADYHIT) then return end
	local p = mo.player
	if p and p.valid 
	and not (p.spectator or p.flashing or p.spinouttimer 
	or p.growshrinktimer > 0 or p.invincibilitytimer or p.hyudorotimer
	or (p.flamedash and p.itemtype == KITEM_FLAMESHIELD)
	or p.bubbleblowup
	or p.curshield == KSHIELD_TOP)
		p.grazesthistic = 0
		searchBlockmap("objects", blockmapsearchfunc, mo, mo.x - 3*mo.radius/2, mo.x + 3*mo.radius/2, mo.y - 3*mo.radius/2, mo.y + 3*mo.radius/2)
		if p.grazesthistic
			--S_StartSound(nil, sfx_graze, p)
			--CONS_Printf(p, "grazing")
		end
		p.driftboost = $+p.grazesthistic*2
		p.grazesthistic = 0
	end
end, MT_PLAYER)