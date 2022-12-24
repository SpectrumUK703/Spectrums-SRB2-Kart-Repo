-- Bikemod by RetroStation, inspired by minenice's Inside Drift

local usefor = "kuze"
local usefortable = {"freeza2nd", "waluigibike", "crazyfrog", "skip", "cacee&milne", "bulletbill", "milne", "boshi", "funky_kong", "pauline", "gemma", "sans", "bikerwario"}

local function canindrift(player)
	local skin = player.mo.skin
	for k, v in pairs(usefortable)
		if skin == v
			return true
		end
	end
	return false
end

local id_outtable = { -- Outside Drift Angles
	[1] = 79, -- 94
	[2] = 100, -- 115
	[3] = 121, -- 136
	[4] = 142, -- 157
	[5] = 163, -- 178
	[6] = 184, -- 199
	[7] = 205, -- 220
	[8] = 226, -- 241
	[9] = 247 -- 262
}

local id_intable = { -- Inside Drift Angles
	[1] = 74, -- 84
	[2] = 70, -- 80
	[3] = 67, -- 77
	[4] = 63, -- 73
	[5] = 60, -- 70
	[6] = 56, -- 66
	[7] = 53, -- 63
	[8] = 49, -- 59
	[9] = 46 -- 56
}


-- Inside Drift in MKWii is busted, and this mod aims to normalize the mechanic.
-- Instead of applying a set amount of momentum during drifts, I instead decided 
-- to apply momentum proportionate to a character's Spark Rate. Additionally, 
-- the above tables' keys correspond to weight, making character support 
-- universal while also making this compatible with Hostmod's Restat. All 
-- applied momentum during drifts respects friction, or lack thereof, so you 
-- won't be gaining ludicrous amounts of speed if you decided to lean outward on 
-- an icy drift turn.

addHook("MobjThinker", function(mo)
	if (mo.player and mo.valid and canindrift(mo.player)) then
		local p = mo.player
		local iangle = id_intable[p.kartweight]
		local oangle = id_outtable[p.kartweight]
		local pks = p.kartstuff
		local turnvalue = FixedDiv(p.cmd.angleturn*FRACUNIT, 800*FRACUNIT)
	
		--if leveltime%(5*TICRATE) == 0 then
			--print(K_GetKartDriftSparkValue(p))
			--print(FRACUNIT)
			--print((FRACUNIT + (30*FRACUNIT/32)))
		--end
		pks[k_driftcharge] = min ($, (K_GetKartDriftSparkValue(p)*2))
		pks[k_accelboost] = max($, FRACUNIT/2) -- +50%
		--pks[k_speedboost] = max($, FRACUNIT/10)
		
		-- Getting hit during a drift results in increased spinout. Amount of 
		-- extra spinout scales with spark rate as well, so god help you if you 
		-- get hit as Flicky.

		if pks[k_spinouttimer] then
			if p.indspin
				--print("Get fucked.")
				--if P_IsObjectOnGround(mo)
					--K_DropItems(p)
				--end
				pks[k_spinouttimer] = ($+1)+(K_GetKartDriftSparkValue(p)/50) -- Scales with spark rate
				p.indspin = false
			elseif p.indboom
				--print("Get fucked.")
				pks[k_spinouttimer] = ($+1)+(K_GetKartDriftSparkValue(p)/50)
				--mo.momz = $*23/20
				p.indboom = false
			end
			--print(pks[k_spinouttimer])
		end
	
		if p.kartstuff[k_drift] > 0 then -- Left Drift
			if p.speed >= 10*mo.scale
			and P_IsObjectOnGround(mo)
			and not (p.pflags & PF_TIMEOVER) then
				if p.cmd.driftturn < 0 then
					P_Thrust(mo, mo.angle - oangle*ANG1, FixedMul(p.speed/23, ((K_GetKartDriftSparkValue(p))*65) - mo.friction))
				elseif p.cmd.driftturn >= 0 then
					P_Thrust(mo, mo.angle + iangle*ANG1, FixedMul(p.speed/18, ((K_GetKartDriftSparkValue(p))*75) - mo.friction))
					if p.speed < 29*mo.scale and p.speed >= 22*mo.scale and (p.cmd.buttons & BT_ACCELERATE) and not (p.cmd.buttons & BT_BRAKE) and not p.kartstuff[k_offroad] then
						P_Thrust(mo, mo.angle, 2*mo.scale/3)
					end
				end
			end
		elseif p.kartstuff[k_drift] < 0 then -- Right Drift
			if p.speed >= 10*mo.scale
			and P_IsObjectOnGround(mo)
			and not (p.pflags & PF_TIMEOVER) then
				if p.cmd.driftturn > 0 then
					P_Thrust(mo, mo.angle + oangle*ANG1, FixedMul(p.speed/23, ((K_GetKartDriftSparkValue(p))*65) - mo.friction))
				elseif p.cmd.driftturn <= 0 then
					P_Thrust(mo, mo.angle - iangle*ANG1, FixedMul(p.speed/18, ((K_GetKartDriftSparkValue(p))*75) - mo.friction))
					if p.speed < 29*mo.scale and p.speed >= 22*mo.scale and (p.cmd.buttons & BT_ACCELERATE) and not (p.cmd.buttons & BT_BRAKE) and not p.kartstuff[k_offroad] then
						P_Thrust(mo, mo.angle, 2*mo.scale/3)
					end
				end
			end
		end
		
		-- Without this, Bike sliptiding would be useless since it would default 
		-- to Kart's default sliptide turning radius, which is actually larger 
		-- than Bike's drift radius. Thank you Ridge Turnpike for making me 
		-- realize this.
		if pks[k_aizdriftstrat] and not pks[k_drift]
			if pks[k_aizdriftstrat] > 0 then -- Left Sliptide
				P_Thrust(mo, mo.angle + iangle*ANG1, FixedMul(p.speed/30, (FRACUNIT) - mo.friction))
			elseif pks[k_aizdriftstrat] < 0 -- Right Sliptide
				P_Thrust(mo, mo.angle - iangle*ANG1, FixedMul(p.speed/30, (FRACUNIT) - mo.friction))
			end
		end
	end
end, MT_PLAYER)

addHook("PlayerSpin", function(p, inf, source)
	if not (((inf and inf.valid) or (source and source.valid)) and canindrift(p)) then return end
	if p.kartstuff[k_drift] then
		p.indspin = true
	end
end)
addHook("PlayerExplode", function(p, inf, source)
	if not (inf and inf.valid and canindrift(p)) then return end
	if p.kartstuff[k_drift]
		p.indboom = true
	end
end)


local function ind_driftbonk(player, mover)
	if not (player.player and mover.player) then return end
	if (mover.z > player.z + player.height)
	or (mover.z + mover.height < player.z) then 
		return
	elseif (CV_FindVar("idc_nocollide") and CV_FindVar("idc_nocollide").value)
	and leveltime < (236 + (20*TICRATE)) then
		return
	elseif (player.player.kartstuff[k_squishedtimer]
	or player.player.kartstuff[k_hyudorotimer]
	or player.player.kartstuff[k_justbumped]
	or player.scale > mover.scale + (mapobjectscale/8)
	or mover.player.kartstuff[k_squishedtimer]
	or mover.player.kartstuff[k_hyudorotimer]
	or mover.player.kartstuff[k_justbumped]
	or mover.scale > player.scale + (mapobjectscale/8))
		return
	elseif (G_BattleGametype() and ((player.player.kartstuff[k_bumper] and !mover.player.kartstuff[k_bumper]) or (mover.player.kartstuff[k_bumper] and !player.player.kartstuff[k_bumper])))
		return
	end
	
	if not player.player.kartstuff[k_drift] then return end
	local we1 = player.player.kartweight
	local wed1 = (we1)/2
	player.player.kartweight = wed1
	K_KartBouncing(mover, player)
	player.player.kartweight = we1
	
end

addHook("MobjCollide", ind_driftbonk, MT_PLAYER)

local function ind_driftbonk2(mover, player)
	if not (player.player and mover.player) then return end
	if (mover.z > player.z + player.height)
	or (mover.z + mover.height < player.z) then 
		return
	elseif (CV_FindVar("idc_nocollide") and CV_FindVar("idc_nocollide").value)
	and leveltime < (236 + (20*TICRATE)) then
		return
	elseif (player.player.kartstuff[k_squishedtimer]
	or player.player.kartstuff[k_hyudorotimer]
	or player.player.kartstuff[k_justbumped]
	or player.scale > mover.scale + (mapobjectscale/8)
	or mover.player.kartstuff[k_squishedtimer]
	or mover.player.kartstuff[k_hyudorotimer]
	or mover.player.kartstuff[k_justbumped]
	or mover.scale > player.scale + (mapobjectscale/8))
		return
	elseif (G_BattleGametype() and ((player.player.kartstuff[k_bumper] and !mover.player.kartstuff[k_bumper]) or (mover.player.kartstuff[k_bumper] and !player.player.kartstuff[k_bumper])))
		return
	end
	
	if not player.player.kartstuff[k_drift] then return end
	local we1 = player.player.kartweight
	local wed1 = (we1)/2
	player.player.kartweight = wed1
	K_KartBouncing(mover, player)
	player.player.kartweight = we1
	
end

addHook("MobjMoveCollide", ind_driftbonk2, MT_PLAYER)