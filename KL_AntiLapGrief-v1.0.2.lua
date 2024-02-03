local FRACUNIT = FRACUNIT
local TICRATE = TICRATE
local k_waypoint = k_waypoint
local k_growshrinktimer = k_growshrinktimer
local k_invincibilitytimer = k_invincibilitytimer

rawset(_G, "alg_enabled" , CV_RegisterVar({
	name = "alg_enabled",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}))

local function NoLapGrief(p, i, s)
	if not alg_enabled.value then return end
	if not (i and i.valid and i.player) then return end
	if not (s and s.valid and s.player) then return end
	-- Altiami: add extra checks on inflictor and source validity
	if s.player.kartstuff[k_invincibilitytimer] > 0
	or s.player.kartstuff[k_growshrinktimer] > 0
	or (HugeQuest and s.player.hugequest.huge > 0) then
		p.laps = $ or 0
		s.player.laps = $ or 0
		if p.laps > s.player.laps -- You lapped the player trying to squish you
			return false
		end
	end
	
	return
end
addHook("ShouldSpin", NoLapGrief)
addHook("ShouldSquish", NoLapGrief)

addHook("ShouldDamage", function(mo, i, s, d)
	if not alg_enabled.value then return end
	-- Altiami: add extra checks on inflictor and source validity
	if not (mo and mo.valid and mo.player) then return end
	if not (i and i.valid and i.player) then return end
	if not (s and s.valid and s.player) then return end
	
	if d < 10000 then
		if s.player.kartstuff[k_invincibilitytimer] > 0 then
			mo.player.laps = $ or 0
			s.player.laps = $ or 0
					
			if mo.player.laps > s.player.laps then
				return false
			end
		end
	end
	
	return
end)

local function ALG_Collide(mo, mo2)
	if not alg_enabled.value then return end
	-- Altiami: add extra checks on inflictor and source validity
	if not (mo and mo.valid and mo.player and mo.player.valid) then return end
	if not (mo2 and mo2.valid and mo2.player and mo2.player.valid) then return end

	local attacker, victim
	--RetroStation: Condense collision code and determine attacker/victim
	if mo.player.kartstuff[k_invincibilitytimer] > 0
	and not mo2.player.kartstuff[k_invincibilitytimer] then
		attacker = mo
		victim = mo2
	elseif mo2.player.kartstuff[k_invincibilitytimer] > 0
	and not mo.player.kartstuff[k_invincibilitytimer] then
		attacker = mo2
		victim = mo
	end
	
	if (attacker and attacker.valid and attacker.player) then
		if attacker.player.kartstuff[k_invincibilitytimer] > 0 
		and ((attacker.z <= victim.z + victim.height) and (attacker.z + attacker.height >= victim.z)) then
			victim.player.laps = $ or 0
			attacker.player.laps = $ or 0
		
			if victim.player.laps > attacker.player.laps then
				return false
			end
		end
	end
	
	return
end

addHook("MobjCollide", ALG_Collide, MT_PLAYER)

addHook("MobjMoveCollide", function(mo2, mo)
	if mo.player then
		return ALG_Collide(mo, mo2)
	end
	
	return
end, MT_PLAYER)
