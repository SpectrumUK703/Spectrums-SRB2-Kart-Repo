--[[
	Programmed by Altiami
	Directly based on the tumble damage effect in Ring Racers by Kart Krew
	DO NOT rerelease without Kart Krew's permission

	Changelog

	v0.3.2.1
		Fixed tumble ignoring iframes when it shouldn't, notably when invincible or grown
			This bug had a side effect of instantly killing players when it shouldn't, which is also now fixed
		Fixed spinning out still occurring after instant death failsafe triggers
		Fixed oversight with spinout timer syncing

	v0.3.2
		Added c-var to adjust tumble behavior after finishing
		Fixed various values not being adjusted to map object scale
		Adjusted tumble timer to mimic spinout timer to avoid fighting with other add-ons
		Hopefully fixed tumble affecting players multiple times per-frame
		Added paranoia check when attempting to tumble a player
		Added additional notices regarding respect of Kart Krew's association
		Fixed spacing error in changelog
		Replaced space indenting with tabs

	v0.3.1
		HugeQuest interop to fix Grown players from tumbling (will still happen in some cases due to HugeQuest bugs)
		Fixed instant kill bug when initial tumble launch would kill if horizontal momentum was too low
		Fixed instant kill bug when initial tumble launch was so fast it overflowed to negative during failsafe checks

	v0.3.0.2
		Changed `tumbleignoreiframes` to `tumbleignoresiframes` to fix conflict with KartMP's `kmp_orbinautfuse`

	v0.3.0.1
		Removed debug statements (when will I learn...)
		Minor optimization touch-ups

	v0.3:
		Adjusted launch angles to consider center instead of feet when target is airborne
		Fixed grow interactions
		Fixed respawn i-frames interfering
	
	v0.2.1:
		C-var to respect i-frames
		C-var to change spinout type
	
	v0.2:
		Fixed spinout timer not being reset on map change
		Fixed overflows when setting tumbletime too high
		Tumble now sets spinout type to orbi type for consistency
		Tumble now ignores i-frames. perish
		Player will be killed if tumbling speed gets too slow in order to prevent softlocks
  
	v0.1:
		Initial
]]

local TICRATE = TICRATE
local FRACBITS = FRACBITS
--local CV_OnOff = CV_OnOff
--local CV_NOINIT = CV_NOINIT
local CV_NETVAR = CV_NETVAR
local CV_CALL = CV_CALL
local CV_FLOAT = CV_FLOAT
local INT32_MAX = INT32_MAX
local INT32_MIN = INT32_MIN
local PST_LIVE = PST_LIVE
--local FF_VERTICALFLIP = 0x200000
--local CV_YesNo = CV_YesNo

local addHook = addHook
local cos = cos
local sin = sin
local max = max
--local min = min

local CV_RegisterVar = CV_RegisterVar
local R_PointToAngle2 = R_PointToAngle2
local R_PointToDist2 = R_PointToDist2
local P_IsObjectOnGround = P_IsObjectOnGround
local FixedMul = FixedMul
local G_BattleGametype = G_BattleGametype

local k_spinouttimer = k_spinouttimer
local k_squishedtimer = k_squishedtimer
local k_spinouttype = k_spinouttype
local pw_flashing = pw_flashing
local k_invincibilitytimer = k_invincibilitytimer
local k_growshrinktimer = k_growshrinktimer
local k_hyudorotimer = k_hyudorotimer
local k_bumper = k_bumper
local k_comebacktimer = k_comebacktimer

local TUMBLE_LAUNCH_THROW_VBASE = 25 << FRACBITS
local TUMBLE_LAUNCH_THROW = 16 << FRACBITS
local TUMBLE_BOUNCE_MIN = 8 << FRACBITS
--local TUMBLE_FLIP_TOGGLE_COUNT = 3 * TICRATE
local TUMBLE_MIN_SPEED = 4 << FRACBITS

local function scaleFixedToMap(fixed)
	return FixedMul(fixed, mapobjectscale)
end

local function resetTumble(player)
	player.tumbleTimer = 0
	player.needsTumbleActivation = false
	player.tumbleSoftlockPrevention = false
	player.kartstuff[k_spinouttimer] = 0 --i really have to do this
	--[[
	player.tumbleFlipCounter = 0
	local playerMo = player.mo
	if playerMo then
		playerMo.frame = $ & ~FF_VERTICALFLIP
	end
	]]
end

local function resetAllTumble()
	for player in players.iterate do
		resetTumble(player)
	end
end

local cv_tumbleMemeEnabled = CV_RegisterVar({
	"tumblememeenabled",
	"On",
	CV_NOINIT|CV_NETVAR|CV_CALL,
	CV_OnOff,
	function(cvar)
		if not cvar.value then
			resetAllTumble()
		end
	end
})

local tumbleTime
local cv_tumbleTime = CV_RegisterVar({
	"tumbletime",
	"3.0",
	CV_FLOAT|CV_NETVAR|CV_CALL,
	{MIN = 0, MAX = INT32_MAX / TICRATE}, --dang it, MrNin
	function(cvar)
		tumbleTime = (cvar.value * TICRATE) >> FRACBITS
	end
})

local tumbleLaunchThrowVBaseScaled
local tumbleLaunchThrowVBaseMapScaled
local cv_baseTumbleUpPower = CV_RegisterVar({
	"basetumbleuppower",
	"1.0",
	CV_FLOAT|CV_NETVAR|CV_CALL,
	{MIN = INT32_MIN, MAX = FixedDiv(INT32_MAX, TUMBLE_LAUNCH_THROW_VBASE)},
	function(cvar)
		tumbleLaunchThrowVBaseScaled = FixedMul(TUMBLE_LAUNCH_THROW_VBASE, cvar.value)
	end
})

local tumbleLaunchThrowScaled
local tumbleLaunchThrowMapScaled
local cv_tumbleSmashPower = CV_RegisterVar({
	"tumblesmashpower",
	"1.0",
	CV_FLOAT|CV_NETVAR|CV_CALL,
	{MIN = INT32_MIN, MAX = FixedDiv(INT32_MAX, TUMBLE_LAUNCH_THROW)},
	function(cvar)
		tumbleLaunchThrowScaled = FixedMul(TUMBLE_LAUNCH_THROW, cvar.value)
	end
})

local cv_tumbleBounceAbsorb = CV_RegisterVar({
	"tumblebounceabsorb",
	"0.667",
	CV_FLOAT|CV_NETVAR,
	{MIN = 0, MAX = INT32_MAX}
})

local tumbleBounceMinScaled
local tumbleBounceMinMapScaled
local cv_tumbleSmashPower = CV_RegisterVar({
	"tumblebounceminpower",
	"1.0",
	CV_FLOAT|CV_NETVAR|CV_CALL,
	{MIN = 0, MAX = FixedDiv(INT32_MAX, TUMBLE_BOUNCE_MIN)},
	function(cvar)
		tumbleBounceMinScaled = FixedMul(TUMBLE_BOUNCE_MIN, cvar.value)
	end
})

local cv_tumbleIgnoresIFrames = CV_RegisterVar({
	"tumbleignoresiframes",
	"Yes",
	CV_NETVAR,
	CV_YesNo
})

local cv_tumbleSpinoutType = CV_RegisterVar({
	"tumblespinouttype",
	"Wipeout",
	CV_NETVAR,
	{Spinout = 0, Wipeout = 1}
})

local TUMBLE_IGNORE_FINISH_TYPE = {Never = 0, Vanilla = 1, Always = 2}
local cv_tumbleIgnoresFinish = CV_RegisterVar({
	"tumbleignoresfinish",
	"Vanilla",
	CV_NETVAR,
	TUMBLE_IGNORE_FINISH_TYPE
})

local function tumblePlayer(player, inflictor, source)
	local playerMo = player.mo
	if not (playerMo and playerMo.valid) then
		return
	end

	if cv_tumbleMemeEnabled.value then
		-- figure out the intended momentums
		player.tumbleMomZ = tumbleLaunchThrowVBaseScaled
		
		--flipped gravity you nerds
		if playerMo.eflags & MFE_VERTICALFLIP then
			player.tumbleMomZ = -$
		end
		
		local refMo = inflictor or source
		if refMo and refMo ~= playerMo then
			local refMoX, refMoY, playerX, playerY = refMo.x, refMo.y, playerMo.x, playerMo.y
			local refMoZ, playerZ = refMo.z, playerMo.z
			-- when grounded, interactions work better at feet. When airborne, better at center
			if not P_IsObjectOnGround(playerMo) then
				refMoZ = $ + refMo.height
				playerZ = $ + playerMo.height
			end
			local smashAngleH = R_PointToAngle2(refMoX, refMoY, playerX, playerY)
			local smashDistH = R_PointToDist2(refMoX, refMoY, playerX, playerY)
			local smashAngleV = R_PointToAngle2(0, refMoZ, smashDistH, playerZ)
			local smashAdjustH = cos(smashAngleV)
			player.tumbleMomX = FixedMul(
					FixedMul(cos(smashAngleH), smashAdjustH),
					tumbleLaunchThrowScaled
				) + refMo.momx
			player.tumbleMomY = FixedMul(
					FixedMul(sin(smashAngleH), smashAdjustH),
					tumbleLaunchThrowScaled
				) + refMo.momy
			--adding to base set above
			player.tumbleMomZ = $ + FixedMul(sin(smashAngleV), tumbleLaunchThrowScaled)
				+ refMo.momz
		else
			player.tumbleMomX = playerMo.momx
			player.tumbleMomY = playerMo.momy
		end

		-- is the player horizontally moving very slowly?
		if player.tumbleSoftlockPrevention and FixedHypot(player.tumbleMomX, player.tumbleMomY) <= TUMBLE_MIN_SPEED then
			--player is probably stuck
			P_DamageMobj(playerMo, nil, nil, 10000)
			return true
		end
		--set up variables
		player.tumbleTimer = tumbleTime
		player.needsTumbleActivation = true
		player.tumbleSoftlockPrevention = true
		--player.tumbleFlipCounter = 0
	end
end

local function isPlayerValid(player)
	return player and player.valid and not player.spectator
end

local function canIgnoreFinishIFrames(minimumIgnorance)
	return cv_tumbleIgnoresFinish.value >= minimumIgnorance
end

local function shouldTumbleFinishedPlayer(player, minimumIgnorance)
	return player.exiting ~= 0 and canIgnoreFinishIFrames(minimumIgnorance)
end

local function shouldTumbleBasedOnFinishState(player, minimumIgnorance)
	return player.exiting == 0 or canIgnoreFinishIFrames(minimumIgnorance)
end

local function tumbleGeneralCheckModded(player)
	return not (
			-- HugeQuest interop
			player.hugequest and player.hugequest.huge > 0
		)
end

local function tumbleGeneralCheck(player, ignorance)
	local kartstuff = player.kartstuff
	return not (
			kartstuff[k_invincibilitytimer]
			or kartstuff[k_growshrinktimer] > 0
			or kartstuff[k_hyudorotimer]
			or G_BattleGametype() and kartstuff[k_bumper] <= 0 and kartstuff[k_comebacktimer]
		) and tumbleGeneralCheckModded(player)
		and shouldTumbleBasedOnFinishState(player, ignorance)
		and not player.needsTumbleActivation -- don't retumble players that're already gonna be tumbled
end

local function tumbleSquishCheck(inflictor, source)
	return inflictor or source
end

local function canTumbleForSquish(player, inflictor, source)
	if
		cv_tumbleMemeEnabled.value
		and tumbleGeneralCheck(player, TUMBLE_IGNORE_FINISH_TYPE.Vanilla)
		and tumbleSquishCheck(inflictor, source)
	then
		return tumblePlayer(player, inflictor, source)
	end
end

local function shouldEatIFramesAtAll(player, ignorance)
	-- check for modded iframe conditions here since we can't rely on vanilla flow
	return cv_tumbleMemeEnabled.value and cv_tumbleIgnoresIFrames.value and tumbleGeneralCheck(player, ignorance)
end

local function eatIFrames(player, inflictor, source)
	--we don't want to return false (prevent damage) if this doesn't pass
	if shouldEatIFramesAtAll(player, TUMBLE_IGNORE_FINISH_TYPE.Vanilla) then
		return true
	end
end

local function canEatIFramesForSquish(player, inflictor, source)
	if shouldEatIFramesAtAll(player, TUMBLE_IGNORE_FINISH_TYPE.Vanilla) and tumbleSquishCheck(inflictor, source) then
		return true
	end
end

local function canTumblePlayerForDamage(target, inflictor, source, damage)
	local player = target.player
	-- force damage in order to always tumble on finish
	if isPlayerValid(player) and shouldTumbleFinishedPlayer(player, TUMBLE_IGNORE_FINISH_TYPE.Always) then
		return true
	end
end

local function canTumbleForSpin(player, inflictor, source)
	if shouldTumbleBasedOnFinishState(player, TUMBLE_IGNORE_FINISH_TYPE.Vanilla) then
		return tumblePlayer(player, inflictor, source)
	end
end

-- same routine
local canTumbleForExplode = canTumbleForSpin

local function eatIFramesForDamage(target, inflictor, source, damage)
	local player = target.player
	if isPlayerValid(player) and shouldEatIFramesAtAll(player, TUMBLE_IGNORE_FINISH_TYPE.Always) then
		--MobjDamage gets run before Kart checks for flashtics. abuse this.
		--don't damage through source; run our own check; force damage doesn't work correctly
		player.powers[pw_flashing] = 0 --you're going into orbit AGAIN
	end
end

local function checkTumbleStuff()
	if cv_tumbleMemeEnabled.value then
		if leveltime <= 0 then
			return
		end

		for player in players.iterate do
			if player and player.valid then
				local playerMo = player.mo
				if player.spectator or player.playerstate ~= PST_LIVE or not (playerMo and playerMo.valid) then
					resetTumble(player)
				elseif player.tumbleTimer then
					local kartstuff = player.kartstuff
					if player.needsTumbleActivation then
						-- here we go
						kartstuff[k_squishedtimer] = 0
						if cv_tumbleIgnoresIFrames.value then
							player.powers[pw_flashing] = 0
						end
						playerMo.momx = player.tumbleMomX
						playerMo.momy = player.tumbleMomY
						playerMo.momz = player.tumbleMomZ
						kartstuff[k_spinouttimer] = player.tumbleTimer
						kartstuff[k_spinouttype] = cv_tumbleSpinoutType.value
						player.needsTumbleActivation = false
					elseif P_IsObjectOnGround(playerMo) then
						local minBounce = tumbleBounceMinScaled
						--flipped gravity you nerds
						if playerMo.eflags & MFE_VERTICALFLIP then
							minBounce = -$
						end
						playerMo.momz = max(
								minBounce,
								FixedMul(-player.tumbleMomZ, cv_tumbleBounceAbsorb.value)
							)
					end
					player.tumbleMomZ = playerMo.momz
				
					--update visual look
					--[[
					player.tumbleFlipCounter = $ + min(player.tumbleTimer, TICRATE)
					if player.tumbleFlipCounter / TUMBLE_FLIP_TOGGLE_COUNT % 2 then
						playerMo.frame = $ | FF_VERTICALFLIP
					else
						playerMo.frame = $ & ~FF_VERTICALFLIP
					end
					]]

					-- mimic spinout time in case it gets changed...somehow
					player.tumbleTimer = kartstuff[k_spinouttimer]
					if player.tumbleTimer == 0 then
						resetTumble(player)
					end
				elseif P_IsObjectOnGround(playerMo) then
					-- reset softlock prevention
					player.tumbleSoftlockPrevention = false
				end
			end
		end
	end
end

local function updateMapScaledValues()
	tumbleLaunchThrowVBaseMapScaled = scaleFixedToMap(tumbleLaunchThrowVBaseScaled)
	tumbleLaunchThrowMapScaled = scaleFixedToMap(tumbleLaunchThrowScaled)
	tumbleBounceMinMapScaled = scaleFixedToMap(tumbleBounceMinScaled)
end

local function doMapLoadStuff()
	if cv_tumbleMemeEnabled.value then
		resetAllTumble()
	end
	-- regardless if it's enabled, update these values
	updateMapScaledValues()
end

-- update these values immediately
updateMapScaledValues()

local function netVarsSync(network)
	tumbleTime = network(tumbleTime)
	tumbleLaunchThrowVBaseScaled = network(tumbleLaunchThrowVBaseScaled)
	tumbleLaunchThrowScaled = network(tumbleLaunchThrowScaled)
	tumbleBounceMinScaled = network(tumbleBounceMinScaled)
	tumbleLaunchThrowVBaseMapScaled = network(tumbleLaunchThrowVBaseMapScaled)
	tumbleLaunchThrowMapScaled = network(tumbleLaunchThrowMapScaled)
	tumbleBounceMinMapScaled = network(tumbleBounceMinMapScaled)
end

addHook("ShouldDamage", canTumblePlayerForDamage)
addHook("MobjDamage", eatIFramesForDamage)
addHook("ShouldSpin", eatIFrames)
addHook("ShouldSquish", canEatIFramesForSquish)
addHook("PlayerSpin", canTumbleForSpin)
addHook("PlayerExplode", canTumbleForExplode)
addHook("PlayerSquish", canTumbleForSquish)
addHook("PostThinkFrame", checkTumbleStuff)
addHook("MapLoad", doMapLoadStuff)
addHook("NetVars", netVarsSync)
