local after_announcer = dusa_an_enable
local after_dynamite = bdd
local dusalapsxf
if (after_announcer and after_dynamite) or not (after_announcer or after_dynamite) then
	print("This has to be added between Daytona Announcer and Bean's Dynamite Derby!")
	return
end

addHook("MapLoad", function()
	dusalapsxf = nil
end)

local function hack_thinkframe()
	if not (gametype == GT_BDD and mapheaderinfo[gamemap].typeoflevel != 0) then return end
	if bdd.gameover
		for p in players.iterate
			if p.spectator or not (p.mo and p.mo.valid) then continue end
			-- yes I'm copying code from Daytona Announcer, I don't want to do something super hacky with numlaps
			if p.position == 1 and dusalapsxf == 1 and gamemap != 3 then
				if server.dusaan == 1 and dusa_an.value == 4 or dusa_an.value == 1 then
					if dusa_an_enable.value == 1 then
						S_StartSound(nil, sfx_dusaw, p)
						S_StartSoundAtVolume(nil, sfx_dusaw, 155)
					end
					dusalapsxf = 2
				end
				if server.dusaan == 2 and dusa_an.value == 4 or dusa_an.value == 2 then
					if dusa_an_enable.value == 1 then
						S_StartSound(nil, sfx_dusatw, p)
						S_StartSoundAtVolume(nil, sfx_dusatw, 155)
					end
					dusalapsxf = 2
				end
				if server.dusaan == 3 and dusa_an.value == 4 or dusa_an.value == 3 then
					if dusa_an_enable.value == 1 then
						S_StartSound(nil, sfx_dusacw, p)
						S_StartSoundAtVolume(nil, sfx_dusacw, 155)
					end
					dusalapsxf = 2
				end
			end
		end
	elseif bdd.numplayersremaining == 2 and 
		for p in players.iterate
			if p.spectator then continue end
			if p.position == 1 and dusalapsxf == nil and gamemap != 3 then
				if server.dusaan == 1 and dusa_an.value == 4 or dusa_an.value == 1 then
					if dusa_an_enable.value == 1
						S_StartSound(nil, sfx_dusafl)
					end
					dusalapsxf = 1
				end
				if server.dusaan == 2 and dusa_an.value == 4 or dusa_an.value == 2 then
					if dusa_an_enable.value == 1
						S_StartSound(nil, sfx_dusatf)
					end
					dusalapsxf = 1
				end
				if server.dusaan == 3 and dusa_an.value == 4 or dusa_an.value == 3 then
					if dusa_an_enable.value == 1
						S_StartSound(nil, sfx_dusacf)
					end
					dusalapsxf = 1
				end
			end
		end
	end
end

--This is so fucking hacky but I want these mods to work together
addHook("ThinkFrame", function()
	if not (dusa_an_enable and bdd) then return end
	if (gametyperules & GTR_CIRCUIT) then
		if after_announcer then
			rawset(_G, "gametype", nil)
			hack_thinkframe()
		else
			hack_thinkframe()
			rawset(_G, "gametype", 0)
		end
	end
end)

addHook("PreThinkFrame", function()
	if not (dusa_an_enable and bdd) then return end
	if (gametyperules & GTR_CIRCUIT) then
		if after_announcer then
			rawset(_G, "gametype", 0)
		else
			rawset(_G, "gametype", nil)
		end
	end
end)

addHook("PostThinkFrame", function()
	rawset(_G, "gametype", nil)
end)
