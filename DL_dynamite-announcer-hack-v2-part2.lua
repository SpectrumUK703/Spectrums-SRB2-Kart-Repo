local after_announcer = dusa_an_enable
local after_dynamite = bdd
if not after_announcer then
	print("This has to be added right after Daytona Announcer!")
	return
end

--This is so fucking hacky but I want these mods to work together
addHook("ThinkFrame", function()
	if not (dusa_an_enable and bdd) then return end
	if (gametyperules & GTR_CIRCUIT) then
		rawset(_G, "gametype", nil)
	end
end)
