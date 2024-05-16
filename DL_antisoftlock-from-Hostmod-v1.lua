local TICRATE = TICRATE
local PF_NOCONTEST = PF_NOCONTEST

--Copied and edited from Hostmod for SRB2 Kart
local cv_antisoftlock = CV_RegisterVar({
	name = "antisoftlock",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

-- RAGESPEC FUNCTIONS
local function ks_countplayers2()
	local pnum = 0
	for p in players.iterate
		pnum = $+1
	end
	return pnum
end

local function ks_countplayers3() -- lol
	local pnum = 0
	for p in players.iterate
		if not p.spectator
			pnum = $+1
		end
	end
	return pnum
end

local ragespec_panictimer = 0
addHook("NetVars", function(net)
	ragespec_panictimer = net(ragespec_panictimer)
end)

-- now for the hook containing player stuff
addHook("ThinkFrame", do
	local ragespec_panicout = true -- (TY: basic softlock handler)
	if ks_countplayers3() == 0 then
		ragespec_panicout = false
	end
	for p in players.iterate
		if not p.exiting and not (p.pflags & PF_NOCONTEST) and not p.spectator then -- (TY: if any player is still racing, we don't need to panic)
			ragespec_panicout = false
		end
	end
	if ragespec_panicout and (ks_countplayers2() > 0) then
		ragespec_panictimer = $ + 1
		if ragespec_panictimer > (32 * TICRATE) and cv_antisoftlock.value then -- shut the up
			chatprint("\x83*A mod interaction caused a softlock. Aborting round.")
			ragespec_panictimer = 0
			G_ExitLevel()
		end
	else
		ragespec_panictimer = 0
	end
end)
-- reset player vars
addHook("MapLoad", function()
	ragespec_panictimer = 0
end)
