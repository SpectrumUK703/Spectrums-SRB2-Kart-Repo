--I know, it'll probably be different from this in Ring Racers
local MF_NOTHINK = MF_NOTHINK 
local MT_SINK = MT_SINK
local MT_PLAYER = MT_PLAYER
local MT_SPB = MT_SPB
local k_growshrinktimer = k_growshrinktimer
local k_invincibilitytimer = k_invincibilitytimer
local TICRATE = TICRATE
local hitlagobjects = {}
local hostmodload = false

local hitlagvar = CV_RegisterVar({
	name = "hitlag_enabled",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

addHook("NetVars", function(net)
	hitlagobjects = net($)
end)

local function hitlag(p, inflictor, source)
	if not hitlagvar.value then return end
	if not (p.mo and p.mo.valid) then return end
	local mo = p.mo
	mo.flags = $|MF_NOTHINK --Freeze!
	table.insert(hitlagobjects, {mo, 10, p.frameangle})
	if inflictor and inflictor.valid
	and (inflictor.player and p.kartstuff[k_growshrinktimer] >= 0
	or (source and source.valid and source.player
	and inflictor ~= source
	and inflictor.type ~= MT_SPB)) --Don't slow down SPBs
		inflictor.flags = $|MF_NOTHINK
		table.insert(hitlagobjects, {inflictor, 10})
	end
end

addHook("PlayerSpin", hitlag)
addHook("PlayerSquish", hitlag)
addHook("PlayerExplode", hitlag)
/*addHook("MobjDamage", function(p, inflictor, source)
	if (inflictor and inflictor.valid and inflictor.type == MT_SINK)
		hitlag(p, inflictor, source)
	end
end, MT_PLAYER)*/

addHook("ThinkFrame", do
	for k, v in pairs(hitlagobjects)
		if not (v[1] and v[1].valid)
			table.remove(hitlagobjects, k)
			continue
		end
		if v[2]
			v[2] = $ and $-1 or 0
			if v[3]
				v[1].player.frameangle = v[3]
			end
		else
			v[1].flags = $ & ~MF_NOTHINK --Unfreeze!
			table.remove(hitlagobjects, k)
		end
	end
	if hostmodload or not (server and HOSTMOD and HM_Scoreboard_AddMod and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "Hitlag", var = "hitlag_enabled"})
	hostmodload = true
end)

addHook("MapLoad", function(map)
	hitlagobjects = {}
end)
