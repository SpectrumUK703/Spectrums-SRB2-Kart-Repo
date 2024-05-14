local FRACUNIT = FRACUNIT
local MT_PLAYER = MT_PLAYER
local GS_CEREMONY = GS_CEREMONY
local KITEM_FLAMESHIELD = KITEM_FLAMESHIELD
local KSHIELD_TOP = KSHIELD_TOP
local DMG_NORMAL = DMG_NORMAL

-- This honestly mostly screws me over, since I use a lightweight character, but I thought it would be funny (I haven't even played MK64 though lol)
-- "since I use a lightweight character" Well, never fucking mind that now lol
local weightbumpspinout = CV_RegisterVar({
	name = "weightbumpspinout",
	defaultvalue = "On",
	possiblevalue = CV_OnOff,
	flags = CV_NETVAR,
	description = "Allows heavier characters to randomly spinout lighter characters by bumping them."
})

local function playerbump(mo, mo2)
	if not (weightbumpspinout.value	-- disabled variable
	and mo and mo.valid and mo2 and mo2.valid and mo.health and mo2.health	-- validity and health checks
	and mo.z + mo.height >= mo2.z
	and mo.z <= mo2.z + mo2.height	-- z position checks
	and mo2.type == MT_PLAYER)	-- not bumping another player
	or (gamestate == GS_CEREMONY)	-- Podium
	or mo.hitlag or mo2.hitlag then return end	-- hitlag
	local p = mo.player
	local p2 = mo2.player
	if not (p and p.valid and p2 and p2.valid)	-- Just in case
	or p.spectator or p2.spectator	-- spectators
	or p.flashing or p2.flashing	-- inv frames
	or p.justbumped or p2.justbumped	-- We just bumped or they did
	or p.rings <= 0 or p2.rings <= 0 or p.spinouttimer or p2.spinouttimer	-- ring sting and other spinout is enough already
	or p.growshrinktimer or p2.growshrinktimer or p.invincibilitytimer or p2.invincibilitytimer	--invincibility/grow
	or p.hyudorotimer or p2.hyudorotimer	--hyudoro
	or (p.flamedash and p.itemtype == KITEM_FLAMESHIELD) or (p2.flamedash and p2.itemtype == KITEM_FLAMESHIELD)	--flamedash
	or p.bubbleblowup or p2.bubbleblowup	--bubble
	or p.curshield == KSHIELD_TOP or p2.curshield == KSHIELD_TOP	--gardentop
	or p.kartweight >= p2.kartweight then return end	-- We're heavier or the same weight
	if P_RandomChance(FRACUNIT*min(8, p2.kartweight-p.kartweight)/64)
		P_DamageMobj(mo, mo2, mo2, dmg, DMG_NORMAL)	-- speen
	end
end

addHook("MobjCollide", playerbump, MT_PLAYER)
addHook("MobjMoveCollide", playerbump, MT_PLAYER)
