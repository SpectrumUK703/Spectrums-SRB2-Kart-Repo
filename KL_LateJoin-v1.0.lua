local STARTTIME = 6*TICRATE + (3*TICRATE/4)

local lj_enabled = CV_RegisterVar({
	name = "lj_enabled",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

local lj_joinwindow = CV_RegisterVar({
	name = "lj_joinwindow",
	defaultvalue = "60",
	flags = CV_NETVAR,
	possiblevalue = {MIN = 30, MAX = 60}
})

local function LJ_FirstLap()
	for p in players.iterate
		if p.spectator then continue end
		if p.laps then
			return true
		end
	end
	
	return false
end

local function LateJoin(p)
	if (leveltime >= STARTTIME + 20*TICRATE and leveltime < STARTTIME + lj_joinwindow.value*TICRATE and not LJ_FirstLap())
	and (p.spectator and p.pflags & PF_WANTSTOJOIN)
	and CV_FindVar("allowteamchange").value then
		p.spectator = false
		p.pflags = $ & ~PF_WANTSTOJOIN
		p.playerstate = PST_REBORN
	end
end

addHook("PlayerThink", LateJoin)


