local after_announcer = dusa_an_enable
local after_dynamite = bdd
local cv_numlaps = CV_FindVar("numlaps")
local cv_cheats = CV_FindVar("cheats")
local resetlapsnexttic
if (after_announcer and after_dynamite) or not (after_announcer or after_dynamite) then
	print("This has to be added between Daytona Announcer and Bean's Dynamite Derby!")
	return
end

local function hack_thinkframe()
	if gametype == GT_BDD and mapheaderinfo[gamemap].typeoflevel != 0 then
		if resetlapsnexttic then
			resetlapsnexttic = nil
			if bdd.gameover
				print("Lucky timing for 1st place! (I'm not fixing this lol)")
				return
			end
			CV_StealthSet(cv_cheats, 1)
			CV_Set(cv_numlaps, resetlapsnexttic)
			CV_StealthSet(cv_cheats, 0)
		end
		if bdd.gameover
			for p in players.iterate
				if p.spectator then continue end
				if p.position == 1 and numlaps ~= p.laps-1
					CV_StealthSet(cv_cheats, 1)
					CV_Set(cv_numlaps, p.laps-1)
					CV_StealthSet(cv_cheats, 0)
				end
			end
		elseif bdd.numplayersremaining == 2 and (bdd.deathmessagetimer == 5 * TICRATE-1 or leveltime == 35)
			for p in players.iterate
				if p.spectator then continue end
				if p.position == 1 and numlaps ~= p.laps
					-- Yes, this does mean if 1st place is about to cross the finish line, they just win lol
					resetlapsnexttic = numlaps
					CV_StealthSet(cv_cheats, 1)
					CV_Set(cv_numlaps, p.laps)
					CV_StealthSet(cv_cheats, 0)
				end
			end
		end
	end
end
--This is so fucking hacky but I want these mods to work together
addHook("ThinkFrame", function()
	cv_numlaps = $ or CV_FindVar("numlaps")
	cv_cheats = $ or CV_FindVar("cheats")
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

addHook("PostThinkFrame", function()
	rawset(_G, "gametype", nil)
end)

addHook("PreThinkFrame", function()
	cv_numlaps = $ or CV_FindVar("numlaps")
	cv_cheats = $ or CV_FindVar("cheats")
	if not (dusa_an_enable and bdd) then return end
	if (gametyperules & GTR_CIRCUIT) then
		if after_announcer then
			rawset(_G, "gametype", 0)
		else
			rawset(_G, "gametype", nil)
		end
	end
end)
