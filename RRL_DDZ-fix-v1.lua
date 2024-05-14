--Can you believe it? This game uses Lua! Anyway, I don't think the snowmen in Diamond Dust should make invincible or huge players stumble
--Although this may have side effects
--I don't care if it's a reference or something, it's stupid for invincible players to tumble when they hit them
local K_StumblePlayer_RingRacers = K_StumblePlayer

rawset(_G, "K_StumblePlayer", function(p)
	if p.invincibilitytimer > 0 or p.growshrinktimer > 0 then return end
	return K_StumblePlayer_RingRacers(p)
end)