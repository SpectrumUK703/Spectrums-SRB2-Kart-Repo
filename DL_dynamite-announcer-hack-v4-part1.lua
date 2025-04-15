local after_announcer = dusa_an_enable
local after_dynamite = bdd
local dusalapsxf
if after_announcer then
	print("This has to be added right before Daytona Announcer!")
	return
end

addHook("MapLoad", function ()
	dusalapsxf = nil
end)	

local function hack_thinkframe()
	if gametype == GT_BDD and mapheaderinfo[gamemap].typeoflevel != 0 and dusa_an_enable.value == 1 and gamemap != 3 then
		if bdd.gameover and dusalapsxf == 1 
			for p in players.iterate
				if p.spectator then continue end
				if p.position == 1 then
					if server.dusaan == 1 and dusa_an.value == 4 or dusa_an.value == 1 then
						S_StartSound(nil, sfx_dusaw, p)--Normal Volume when you hear your place
						S_StartSoundAtVolume(nil, sfx_dusaw, 155)
						dusalapsxf = 2
					end
					if server.dusaan == 2 and dusa_an.value == 4 or dusa_an.value == 2 then
						S_StartSound(nil, sfx_dusatw, p)--Normal Volume when you hear your place
						S_StartSoundAtVolume(nil, sfx_dusatw, 155)
						dusalapsxf = 2
					end
					if server.dusaan == 3 and dusa_an.value == 4 or dusa_an.value == 3 then
						S_StartSound(nil, sfx_dusacw, p)--Normal Volume when you hear your place
						S_StartSoundAtVolume(nil, sfx_dusacw, 155)
						dusalapsxf = 2
					end
				end
			end
		elseif bdd.numplayersremaining == 2 and dusalapsxf == nil then
			if server.dusaan == 1 and dusa_an.value == 4 or dusa_an.value == 1 then
				S_StartSound(nil, sfx_dusafl)
				dusalapsxf = 1
			end
			if server.dusaan == 2 and dusa_an.value == 4 or dusa_an.value == 2 then
				S_StartSound(nil, sfx_dusatf)
				dusalapsxf = 1
			end
			if server.dusaan == 3 and dusa_an.value == 4 or dusa_an.value == 3 then
				S_StartSound(nil, sfx_dusacf)
				dusalapsxf = 1
			end
		end
	end
end
--This is so fucking hacky but I want these mods to work together
addHook("ThinkFrame", function()
	if not (dusa_an_enable and bdd) then return end
	if (gametyperules & GTR_CIRCUIT) then
		hack_thinkframe()
		rawset(_G, "gametype", 0)
	end
end)
