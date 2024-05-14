--shield types for if I decide to/when I figure out how to do more with this: KITEM_FLAMESHIELD, KITEM_BUBBLESHIELD, KITEM_LIGHTNINGSHIELD
local protectiveshield = {}
-- I don't know which of these actually are damaging flames lmao
protectiveshield[MT_FLAMEJETFLAME] = KITEM_FLAMESHIELD
protectiveshield[MT_FLAMEJETFLAMEB] = KITEM_FLAMESHIELD
protectiveshield[MT_DARKVILE_FLAME] = KITEM_FLAMESHIELD
protectiveshield[MT_FORGEFLAME] = KITEM_FLAMESHIELD
protectiveshield[MT_FLAME] = KITEM_FLAMESHIELD
protectiveshield[MT_SSCANDLE_FLAME] = KITEM_FLAMESHIELD

addHook("ShouldDamage", function(mo, inf, src, dmg, dmgtype)
	if not (mo and mo.valid and mo.player and inf and inf.valid) then return end
	local p = mo.player
	if p.itemtype and inf.type and protectiveshield[inf.type] and protectiveshield[inf.type] == p.itemtype
		return false
	end
end, MT_PLAYER)