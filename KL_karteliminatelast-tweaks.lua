local k_position = k_position
local PF_TIMEOVER = PF_TIMEOVER
local TICRATE = TICRATE
local raceexittime = 5*TICRATE + (2*TICRATE/3)
local jointime = 6*TICRATE + (3*TICRATE/4) + (20*TICRATE)
local playercount
local ragespec
local hostmodload = false
local karteliminatelast = CV_FindVar("karteliminatelast")


--Function copied from Friendmod and edited
local function welcometofuckingdie(p)
	p.pflags = $|PF_TIMEOVER
	if p.mo and p.mo.valid
		local mo = p.mo
		--S_StopSound(mo)
		P_DamageMobj(mo, nil, nil, 10000)
		--S_StartSound(mo, sfx_kc3b)
		--K_SpawnMineExplosion(mo, p.skincolor)
		P_DamageMobj(mo, nil, nil, 10000)
	end
	S_ChangeMusic("krfail", true, p)
end

--Rest of this mod based on my MK-Style last-elimination mod
local function theresultsarein(p)
	if p.mo and p.mo.valid
		local mo = p.mo
		S_StartSound(mo, sfx_klose)
		local fakeplayer = P_SpawnMobj(mo.x, mo.y, mo.z, MT_THOK)
		fakeplayer.skin = mo.skin
		fakeplayer.state = mo.state
		fakeplayer.flags = mo.flags
		fakeplayer.flags2 = mo.flags2
		fakeplayer.eflags = mo.eflags
		fakeplayer.renderflags = mo.renderflags
		fakeplayer.sprite = mo.sprite
		fakeplayer.sprite2 = mo.sprite2
		fakeplayer.momx = mo.momx
		fakeplayer.momy = mo.momy
		fakeplayer.momz = mo.momz
		fakeplayer.pmomz = mo.pmomz
		fakeplayer.friction = mo.friction
		fakeplayer.scale = mo.scale
		fakeplayer.destscale = mo.destscale
		fakeplayer.color = mo.color
		fakeplayer.frame = mo.frame
		fakeplayer.angle = mo.angle
		fakeplayer.tics = 99999
		P_DamageMobj(mo, nil, nil, 10000)
	end
	chatprintf(p, "\x82The results are in! The race is over.")
	S_ChangeMusic("krlose", true, p)
end

local function ismapmariokart(map)
	local mapinfo = mapheaderinfo[map]
	local mapname = mapinfo.lvlttl
	return mapname:find("MK")
	or mapname:find("SNES")
	or mapname:find("N64")
	or mapname:find("GC")
	or mapname:find("Wii") --Also covers WiiU
	or mapname:find("GBA")
	or mapname:find("DS") --Also covers 3DS
end

local function karteliminatelasttweaked(arg1)
	if arg1.value and server
		COM_BufInsertText(server, "karteliminatelast no")
	end
end

local karteliminatelasttweaked = CV_RegisterVar({
	name = "karteliminatelasttweaked",
	defaultvalue = "On",
	flags = CV_NETVAR|CV_CALL,
	possiblevalue = CV_OnOff,
	func = karteliminatelasttweaked
})

addHook("NetVars", function(net)
	playercount = net($)
	ragespec = net($)
end)

addHook("ThinkFrame", do
	if not (server and karteliminatelasttweaked.value) then return end
	karteliminatelast = $ or CV_FindVar("karteliminatelast")
	if karteliminatelast.value
		COM_BufInsertText(server, "karteliminatelast no")
	end
	if G_BattleGametype() then return end
	if leveltime == jointime+1
		playercount = 0
		ragespec = false
		for p in players.iterate
			if p.spectator then continue end
			playercount = $+1
		end
	end
	if not ragespec and leveltime > jointime+1
		local currentplayercount = 0
		local finishedcount = 0
		local position = 0
		local lastplayer = nil
		for p in players.iterate
			if p.spectator then continue end
			if (p.pflags & PF_TIMEOVER)
				p.lives = 0
				ragespec = true
				continue
			end
			currentplayercount = $+1
			if p.exiting
				finishedcount = $+1
			elseif p.kartstuff[k_position] > position
				position = p.kartstuff[k_position]
				lastplayer = p
			end
		end
		if currentplayercount ~= playercount
			ragespec = true
			return
		end
		if playercount >= 2 and finishedcount == playercount-1
		and lastplayer and lastplayer.valid and not lastplayer.spectator
			ragespec = true --They didn't ragespec, but after this part, the code shouldn't need to run
			if ismapmariokart(gamemap)
				theresultsarein(lastplayer)
			else
				welcometofuckingdie(lastplayer)
			end
			lastplayer.pflags = $|PF_TIMEOVER
			lastplayer.lives = 0
		end
	end
	if hostmodload or not (server and HOSTMOD and HM_Scoreboard_AddMod and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "LastTweaks", var = "karteliminatelasttweaked"})
	hostmodload = true
end)