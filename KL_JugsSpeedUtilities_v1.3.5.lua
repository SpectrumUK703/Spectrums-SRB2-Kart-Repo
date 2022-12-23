local CVAR_BoostQueueing = CV_RegisterVar(
{
	name = "bq_enable",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_YesNo
}
)

local CVAR_BQBurstDisable = CV_RegisterVar(
{
	name = "bq_burstdisable",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_YesNo
}
)

local CVAR_AdditiveMTs = CV_RegisterVar(
{
	name = "am_enable",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_YesNo
}
)

local CVAR_MTAddMult = CV_RegisterVar(
{
	name = "am_mtaddmult",
	defaultvalue = "1.0",
	flags = CV_NETVAR|CV_FLOAT,
	PossibleValue = CV_Unsigned
}
)

local CVAR_MTApplyMultAfterFirst = CV_RegisterVar(
{
	name = "am_applymultafterfirst",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_YesNo
}
)

local CVAR_MTBurstDisable = CV_RegisterVar(
{
	name = "am_burstdisable",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_YesNo
}
)

local CVAR_SpeedPadStoring = CV_RegisterVar(
{
	name = "sps_enable",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_YesNo
}
)

local CVAR_JSU_Debug = CV_RegisterVar(
{
	name = "jsu_debug",
	defaultvalue = "Off",
	flags = CV_NETVAR,
	PossibleValue = CV_YesNo
}
)

local defaultTurboTimer = 
{
	blue 	= 20,
	red 	= 50,
	rainbow = 125
}

local loadedHostmodExtras = false

-- the most epic optimization
local FRACUNIT = FRACUNIT

local MTSETTING	= 1
local BQSETTING = 2

local SPEEDPAD	= 1280

local function isPlayerBursting(mobj, settingType)
	if ac_active == nil or 
		not ac_active.value then return end

	local isBurstEnabled = 
		mobj.player.trickstyle == TS_BURST and 
		mobj.player.trickboost > 0

	if isBurstEnabled == false then
		return false
	elseif settingType == MTSETTING then
		return isBurstEnabled and CVAR_MTBurstDisable.value == 1
	elseif settingType == BQSETTING
		return isBurstEnabled and CVAR_BQBurstDisable.value == 1
	else
		return isBurstEnabled
	end
end

local function printdebug(msg)
	if CVAR_JSU_Debug.value == 0 then return end
	print(msg)
end

local function boostQueueHandling(mobj)
	-- don't do anything on the preticker
	-- seems to cause desyncs otherwise
	if leveltime < 2 then return end

	if CVAR_BoostQueueing.value == 0 and
		CVAR_AdditiveMTs.value 	== 0 and
		CVAR_SpeedPadStoring.value == 0 then
		return end

	local player 		= mobj.player

	if P_PlayerInPain(player) 			 		or
		player.kartstuff[k_spinouttimer] > 0 	or 
		player.kartstuff[k_squishedtimer] > 0 	or
		isPlayerBursting(mobj, BQSETTING) 		then
			
		mobj.storedMT 		= 0
		mobj.oldMTValue 	= 0
		mobj.applyMTAfter 	= false
	end

	local sneakerTimer = player.kartstuff[k_sneakertimer]

	-- have to recreate this because otherwise mts while boosting get eaten
	if player.kartstuff[k_driftend] == 1 and
		P_IsObjectOnGround(mobj) == true then
		local driftSpark = player.kartstuff[k_driftcharge]

		if driftSpark > 0 then
			
			-- afaik there is no good mathematical way of doing this so don't @ me
			local MTobtained = 0
			local driftSparkValue = K_GetKartDriftSparkValue(player)

			if 		driftSpark >= (driftSparkValue * 4) then
				MTobtained = defaultTurboTimer.rainbow
			elseif 	driftSpark >= (driftSparkValue * 2) then
				MTobtained = defaultTurboTimer.red
			elseif 	driftSpark >= driftSparkValue 		then
				MTobtained = defaultTurboTimer.blue
			end
			
			if CVAR_AdditiveMTs.value == 1 	and 
				CVAR_MTAddMult.value > 0 	and
				MTobtained > 0 				and
				isPlayerBursting(mobj, MTSETTING) == false then

				local multValue = FRACUNIT;
				mobj.storedMT = $ or 0

				if CVAR_MTAddMult.value ~= multValue then

					printdebug(CVAR_MTApplyMultAfterFirst.value)

					if (CVAR_MTApplyMultAfterFirst.value == 1 and
						(mobj.storedMT > 0 or player.kartstuff[k_driftboost] > 0)) or 
						CVAR_MTApplyMultAfterFirst.value == 0 then

						multValue = CVAR_MTAddMult.value
						printdebug("Applying multiplier after first miniturbo...")
					end
				end

				local addedValue = FixedInt(FixedMul(MTobtained * FRACUNIT, multValue))

				if CVAR_BoostQueueing.value == 1 and sneakerTimer > 0 then
					mobj.storedMT = $ + addedValue
					printdebug("Added drift frames: " + mobj.storedMT + "(" + addedValue + ")")
				else
					player.kartstuff[k_driftboost] = $ + addedValue
					printdebug("Added drift frames: " + player.kartstuff[k_driftboost] + "(" + addedValue + ")")
				end

			elseif CVAR_BoostQueueing.value == 1
				mobj.storedMT = $ or 0

				if sneakerTimer > 0 then
					if mobj.storedMT < MTobtained then
						mobj.storedMT = MTobtained
						printdebug("Set drift frames: " + mobj.storedMT)
					end
				end
			end
		end
	end

	if CVAR_BoostQueueing.value == 1 and isPlayerBursting(mobj, BQSETTING) == false then
		if sneakerTimer > 0 then
			mobj.applyMTAfter = true

			if mobj.oldMTValue == nil then
				mobj.oldMTValue = 0
			end
	
			if mobj.oldMTValue > 0 then
				printdebug("Caught drift frames from before boost: " + mobj.oldMTValue)
				mobj.storedMT 	= mobj.oldMTValue
				mobj.oldMTValue = 0
			end
	
		elseif mobj.applyMTAfter == true then
			if mobj.storedMT == nil then
				mobj.storedMT = 0
			end

			printdebug("Final drift frames after boost: " + mobj.storedMT)
			player.kartstuff[k_driftboost] = mobj.storedMT
			mobj.storedMT 		= 0
			mobj.applyMTAfter 	= false
			
		else
			mobj.oldMTValue = player.kartstuff[k_driftboost]
			-- printdebug("Stored MT frames: "..mobj.oldMTValue)
		end
	end

	if CVAR_SpeedPadStoring.value == 1 then
		local inSpeedPadFoF = P_ThingOnSpecial3DFloor(mobj)

		if inSpeedPadFoF ~= nil then
			inSpeedPadFoF = ($.special & SPEEDPAD) == SPEEDPAD
		end

		if ((P_PlayerTouchingSectorSpecial(player, 3, 5) ~= nil and
			P_IsObjectOnGround(mobj) == true) 					or
			inSpeedPadFoF 		== true)						and
			mobj.lastDriftAngle ~= 0							and
			(mobj.dashPadStoring == 0 or mobj.dashPadStoring == nil) then
			
			player.kartstuff[k_drift] 		= mobj.lastDriftAngle
			player.kartstuff[k_driftcharge] = mobj.lastDriftValue
			mobj.dashPadStoring = 3
			printdebug("Initiating speed pad storing...")

		elseif mobj.dashPadStoring ~= nil and
			mobj.dashPadStoring > 0 then
				
			mobj.dashPadStoring = $ - 1
		else
			mobj.lastDriftAngle = player.kartstuff[k_drift]
			mobj.lastDriftValue = player.kartstuff[k_driftcharge]
		end
	end

	-- print("Sneaker Timer: " + sneakerTimer)
	-- print("Drift Timer: " 	+ player.kartstuff[k_driftboost])
end

local function hostmodHandling()
	if leveltime == 1 then
		if loadedHostmodExtras then return end
		local HMscoreBoardCVAR = CV_FindVar("hm_scoreboard")
	
		if HMscoreBoardCVAR ~= nil and loadedHostmodExtras == false then
			HM_Scoreboard_AddTip({msg 	= "With Boost Queueing, drifting into boost pads will result "..
			"in the mini-turbo appearing at the end of the boost for an extra pinch of speed!", cvartrue = "bq_enable"})
			HM_Scoreboard_AddTip({msg 	= "With Additive Miniturbos and Boost Queueing, it's possible to build up significant "..
			"amounts of mini-turbos before your boosts run out, making you go faster for longer!", cvartrue = "am_enable"})
			HM_Scoreboard_AddTip({msg 	= "With Speed Pad Storing, be careful not to bonk into walls after "..
			"drifting into a speed pad, or you'll lose speed!", cvartrue = "sps_enable"})
			HM_Scoreboard_AddTip({msg 	= "With Speed Pad Storing, take advantage of speed pads sending you on a direction "..
			"to build large miniturbos that would not be possible otherwise.", cvartrue = "sps_enable"})
	
			HM_Scoreboard_AddMod({disp 	= "Boost Queueing", 		var = "bq_enable"})
			HM_Scoreboard_AddMod({disp 	= "Additive Miniturbos", 	var = "am_enable"})
			HM_Scoreboard_AddMod({disp	= "Speed Pad Storing", 		var = "sps_enable"})
	
			loadedHostmodExtras = true
		end		
	end
end



addHook("MobjThinker", 	boostQueueHandling, MT_PLAYER)
addHook("ThinkFrame",	hostmodHandling)