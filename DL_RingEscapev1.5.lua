-- Ring Escape
-- Spend Rings to tech out of stuns!
local cv_escapecost = CV_RegisterVar({
	name = "Ring Escape Cost",
	defaultvalue = "10",
	flags = CV_NETVAR,
	description = "Amount of Rings used when teching out of stun.",
	possiblevalue = {MIN = 1, MAX = 20} -- so uh what if something increases max rings?
})

local cv_escapeflashcut = CV_RegisterVar({
	name = "Escape Risk",
	defaultvalue = "2",
	flags = CV_NETVAR,
	description = "How risky techs are, via removing invulnerability. Higher numbers = less tech invuln.",
	possiblevalue = {MIN = 1, MAX = 10}
})
local cv_escapehitlag = CV_RegisterVar({
	name = "Escape During Hitlag",
	defaultvalue = "Off",
	flags = CV_NETVAR,
	description = "Can teching be done during hitlag/before taking ring damage?",
	possiblevalue = CV_OnOff
})
--[[local cv_escapeminrings = CV_RegisterVar({
	name = "Ring Escape Threshold",
	defaultvalue = "1",
	flags = CV_NETVAR,
	description = "The minimum amount of Rings required to tech.",
	possiblevalue = {MIN = 1, MAX = 20}
})
]]
-- UNUSED, MAY ADD LATER: Not really neccesary??????? I'll be thinking more about this one

--[[local cv_escapecooldown = CV_RegisterVar({
	--name = "Escape Cooldown",
	--defaultvalue = "0",
	--flags = CV_NETVAR,
	--description = "How long of a cooldown teching has, in tics. 1 second = 35 tics.",
	--possiblevalue = {MIN = 0, MAX = 70}
})
]]
-- UNUSED, MAY ADD LATER: worried about bloating, plus the stuff I wanna do with this (ring counter turning blue when in cooldown) isn't fully exposed to lua iirc

local cv_escaperingburst = CV_RegisterVar({
	name = "Ring Burst on Escape",
	defaultvalue = "On",
	flags = CV_NETVAR,
	description = "If on, teching causes spent rings to scatter instead of disappearing.",
	possiblevalue = CV_OnOff
})

--[[local cv_kartstatfactor = CV_RegisterVar({
	name = Stat-Based Risk,
	defaultvalue = "Off",
	flags = CV_NETVAR,
	description = "If on, Escape Risk is overriden and determined by kart stats.",
	possiblevalue = CV_OnOff
})
]]
-- UNUSED, MAY ADD LATER: tbh i just don't feel like doing many fixed point math shenanigans rn

addHook("PlayerSpawn", function(player)
	player.spindashInput = false
	player.canEscape = false
	player.tumbleDash = false
	player.escapeLock = 0
end)

addHook("PreThinkFrame", function(player)
	for player in players.iterate do
		if player.cmd.buttons == (BT_DRIFT|BT_ACCELERATE|BT_BRAKE) then
			-- player is using spindash input
			player.spindashInput = true
		else
			player.spindashInput = false
		end
	end
end)

addHook("ThinkFrame", function(player)
	for player in players.iterate do
		if cv_escapehitlag.value == 0 then
			player.escapeLock = player.mo.hitlag
		end
		if player.spindashInput and player.rings >= 1 and player.turbine == 0 and player.escapeLock == 0 then
			if player.spinouttimer > 5 then
				player.canEscape = true
			elseif player.tumblebounces > 0 and player.tumbleheight > 10 then
				player.canEscape = true
				player.tumbleDash = true
			else
				player.canEscape = false
				player.tumbleDash = false
			end
			if player.canEscape == true then
				player.spinouttimer = 0
				player.wipeoutslow = 0
				if player.flashing > 0 then
					player.flashing = player.flashing / cv_escapeflashcut.value
				end
				if player.tumbleDash == true then
					player.tumblebounces = 0
					player.tumbleheight = 0
					P_InstaThrust(player.mo, player.mo.angle, 50 * mapheaderinfo[gamemap].mobj_scale)
					-- stop all other momentum and push the player forward
					player.mo.momz = 5 * mapheaderinfo[gamemap].mobj_scale -- give them a hop too
					player.tumbleDash = false
				end
				if cv_escaperingburst.value == 1 then
					P_PlayerRingBurst(player, cv_escapecost.value)
				else
					player.rings = player.rings - cv_escapecost.value
				end
				S_StartSound(player.mo, sfx_s1c3)
				player.canEscape = false
				--player.escapeLock = cv_techcooldown.value
			end
		end
		--if player.escapeLock != 0 then
			--player.escapeLock = player.escapeLock - 1
			-- how to color ring hud blue while in cooldown?
		--end
	end
end)

-- made by NikoReiesu
-- big thanks to the kart krew discord, especially to the guys in #graphics-lua-misc who had to put up with my big dummy ass