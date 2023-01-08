//Based on KartMP's K_handleRespawn function
addHook("MapLoad", function()
	for p in players.iterate
		p.softlocktimer = 0
		p.othersoftlocktimer = 0
	end
end)

local starpostspawns = CV_RegisterVar({
	name = "starpostspawns",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

addHook("ThinkFrame", do
	if not starpostspawns.value then return end
	for p in players.iterate
		if p.spectator or not p.mo or not p.mo.valid
			p.softlocktimer = 0
			continue
		end
		local mo = p.mo
		if P_IsObjectOnGround(mo)
			p.softlocktimer = $ and $-1
			p.othersoftlocktimer = 0
		end
		if p.kartstuff[k_respawn]
			if (p.softlocktimer 
			or (p.othersoftlocktimer and p.othersoftlocktimer > TICRATE*5))
			and not P_IsObjectOnGround(mo) //We may be softlocked
				local sector = mo.subsector.sector
				for mobj in sector.thinglist()
					if mobj.type == MT_STARPOST //Spawn closer to the starpost
						P_TryMove(mo, mobj.x, mobj.y)
						p.softlocktimer = 0
						p.othersoftlocktimer = 0
						break
					end
				end
			end
			if P_IsObjectOnGround(mo)
				p.softlocktimer = TICRATE*2
				p.othersoftlocktimer = 0
			else
				p.othersoftlocktimer = $ and $+1 or 1
			end
		end
	end
end)