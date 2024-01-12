--Allows you to extend your sneaker timer with smart drift play

--Performance Stuff
local k_driftboost = k_driftboost
local k_sneakertimer = k_sneakertimer
local k_driftcharge = k_driftcharge
local k_driftend = k_driftend
local FRACUNIT = FRACUNIT

--Used for booststack check
local booststack = booststack

local cv_sneakerextender = CV_RegisterVar({
	name = "sneakerextend",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
})

local cv_driftstacking = CV_RegisterVar({
	name = "driftstacking",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
})

local cv_driftstackingcap = CV_RegisterVar({
    name = "driftstackingcap",
    defaultvalue = "140",
    flags = CV_NETVAR,
	possiblevalue =  {MIN = 125, MAX = 999}
})


local  cv_boostefx = CV_RegisterVar({
	name = "boostingeffects",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
})

local defaultTurboTimer = 
{
	blue 	= 20,
	red 	= 50,
	rainbow = 125
}


local function sneakerextend(p)
	--check for booststack and disable if found since this does the same thing
	if CV_FindVar("booststack") then
		if booststack.running then return end
	end

	--detect sneaker
	if p.lfsneaker then
		--if there is drift time
		if p.lfdriftboost then
			--hold sneaker at 1 until drift timers expire
			p.kartstuff[k_sneakertimer] = max($1, 1)
		end

	end
end

local function driftstacking(p)
	--check for JugsSpeedUtils and disable if found since this does the same thing
	if CV_FindVar("am_enable") then
		if CV_FindVar("am_enable").value then return end
	end

	--Code taken and modified from Jug's Speed Utilities
	-- have to recreate this because otherwise mts while boosting get eaten
	if p.kartstuff[k_driftend] == 1 and
		P_IsObjectOnGround(p.mo) == true then
		local driftSpark = p.kartstuff[k_driftcharge]

		if driftSpark > 0 then
			
			-- afaik there is no good mathematical way of doing this so don't @ me
			local MTobtained = 0
			local driftSparkValue = K_GetKartDriftSparkValue(p)

			if 		driftSpark >= (driftSparkValue * 4) then
				MTobtained = defaultTurboTimer.rainbow
			elseif 	driftSpark >= (driftSparkValue * 2) then
				MTobtained = defaultTurboTimer.red
			elseif 	driftSpark >= driftSparkValue 		then
				MTobtained = defaultTurboTimer.blue
			end
			
			if  MTobtained > 0 then
				local multValue = FRACUNIT;
				local addedValue = FixedInt(FixedMul(MTobtained * FRACUNIT, multValue))
				
				p.kartstuff[k_driftboost] = min($ + addedValue, cv_driftstackingcap.value)
			end
		end
	end
end

local function boostefx(p)
	if	p.kartstuff[k_sneakertimer]
		local thok = P_SpawnMobj(p.mo.x, p.mo.y, p.mo.z, MT_THOK)
		thok.fuse = 6
		thok.scale = p.mo.scale*3/5
		
		if p.kartstuff[k_driftboost] > 49 and cv_sneakerextender.value then
			thok.color = (1+leveltime%(MAXSKINCOLORS-1))
		elseif p.kartstuff[k_driftboost] > 19 and cv_sneakerextender.value then
			thok.color = SKINCOLOR_KETCHUP
		elseif p.kartstuff[k_driftboost] > 0 and cv_sneakerextender.value then
			thok.color = SKINCOLOR_SAPPHIRE
		elseif not p.kartstuff[k_driftboost] or not cv_sneakerextender.value then
			thok.color = p.skincolor
		end
		

	end
	
	if	p.kartstuff[k_driftboost]
		if leveltime % 4 == 0
			local fl = P_MobjFlip(p.mo)
			local spark = P_SpawnMobj(p.mo.x - FRACUNIT * 20,p.mo.y,p.mo.z - FRACUNIT * 5 + (12 * FRACUNIT * fl),MT_DRIFTDUST)
			local spark2 = P_SpawnMobj(p.mo.x + FRACUNIT * 20,p.mo.y,p.mo.z - FRACUNIT * 5 + (12 * FRACUNIT * fl),MT_DRIFTDUST)
			spark.colorized = true
			spark.momz = (2 * FRACUNIT) * fl
			spark.fuse = 6
			spark.state = S_NIGHTSPARKLE1
			spark.scale =  p.mo.scale*2
			
			spark2.colorized = true
			spark2.momz = (2 * FRACUNIT) * fl
			spark2.fuse = 6
			spark2.state = S_NIGHTSPARKLE1
			spark2.scale =  p.mo.scale*2
			
			if	p.kartstuff[k_driftboost] > 49 then
				spark.color = (1+leveltime%(MAXSKINCOLORS-1))
				spark2.color = (1+leveltime%(MAXSKINCOLORS-1))
			elseif p.kartstuff[k_driftboost] > 19 then
				spark.color = SKINCOLOR_KETCHUP
				spark2.color = SKINCOLOR_KETCHUP
			else
				spark.color = SKINCOLOR_SAPPHIRE
				spark2.color = SKINCOLOR_SAPPHIRE
			end

		end
	end	
end

addHook("PlayerThink", function(p)
	if not cv_sneakerextender.value and not cv_driftstacking.value and not cv_boostefx.value return end

	if cv_sneakerextender.value then
		sneakerextend(p)
	end
	
	if cv_driftstacking.value then
		driftstacking(p)
	end
	
	if cv_boostefx.value then
		boostefx(p)
	end
	
	p.lfsneaker = p.kartstuff[k_sneakertimer]
	p.lfdriftboost = p.kartstuff[k_driftboost]	
end)
