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
	if i and i.valid
		if s and s.player
			if s.player.kartstuff[k_invincibilitytimer] > 0
			or s.player.kartstuff[k_growshrinktimer] > 0
			or (HugeQuest and s.player.huge > 0) then
				p.laps = $ or 0
				s.player.laps = $ or 0
				if p.laps > s.player.laps -- You lapped the player trying to squish you
					return false
				end
			end
		end
	end
end
addHook("ShouldSpin", NoLapGrief)
addHook("ShouldSquish", NoLapGrief)

addHook("ShouldDamage", function(mo, i, s, d)
	if not alg_enabled.value then return end
	if not (mo and mo.valid and mo.player) then return end
	if d < 10000 then
		if (i and i.valid and i.type == MT_PLAYER) then
			if s and s.player then
				if s.player.kartstuff[k_invincibilitytimer] > 0 then
					mo.player.laps = $ or 0
					s.player.laps = $ or 0
					
					if mo.player.laps > s.player.laps then
						return false
					end
				end
			end
		end
	end
end)

addHook("MobjCollide", function(mo, mo2)
	if not alg_enabled.value then return end
	if not (mo and mo.valid and mo.player) then return end
	if not (mo2 and mo2.valid and mo2.player) then return end
	local p1 = mo.player
	local p2 = mo2.player
	
	if p2.kartstuff[k_invincibilitytimer] > 0 
	and ((mo2.z <= mo.z + mo.height) and (mo2.z + mo2.height >= mo.z)) then
		p1.laps = $ or 0
		p2.laps = $ or 0
		
		if p1.laps > p2.laps then
			return false
		end
	end
end, MT_PLAYER)

addHook("MobjCollide", function(mo2, mo)
	if not alg_enabled.value then return end
	if not (mo and mo.valid and mo.player) then return end
	if not (mo2 and mo2.valid and mo2.player) then return end
	local p1 = mo.player
	local p2 = mo2.player
	
	if p2.kartstuff[k_invincibilitytimer] > 0 
	and ((mo2.z <= mo.z + mo.height) and (mo2.z + mo2.height >= mo.z)) then
		p1.laps = $ or 0
		p2.laps = $ or 0
		
		if p1.laps > p2.laps then
			return false
		end
	end
end, MT_PLAYER)