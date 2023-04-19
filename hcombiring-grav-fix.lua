if not hcombi then return end

local BASE_DISTANCE = 450
local mapscale = FRACUNIT
local MAX_DISTANCE = BASE_DISTANCE * mapscale
local MAX_DISTANCE_THRESHOLD = BASE_DISTANCE * mapscale

-- Sync our gargoyle.
addHook("NetVars", function(sync)
	BASE_DISTANCE = sync(BASE_DISTANCE)
	mapscale = sync(mapscale)
	MAX_DISTANCE = sync(MAX_DISTANCE)
	
	--hcombi = sync(hcombi)
end)

local function HandleRespawnSync(mobj, player)
	-- kill all our momentum
	mobj.momx, mobj.momy, mobj.momz = 0, 0, 0
	-- set our angle
	mobj.angle = player.mo.angle
	-- respawn stuff
	mobj.player.combi_respawn = true
	player.combi_respawn = true
	player.mo.color = player.skincolor
	player.mo.colorized = false
	mobj.color = mobj.player.skincolor
	mobj.colorized = false
end

hcombi.PullVarThink = function(player, has_partner)
	local partner = hcombi.ReturnPartner(player, has_partner)
	local plymo = player.mo
	
	-- set our pull
	plymo.pull_xy = hcombi.cv_combipull.value
	partner.pull_xy = hcombi.cv_combipull.value
	plymo.pull_z = hcombi.cv_combipull.value
	partner.pull_z = hcombi.cv_combipull.value
	
	if player.cmd.buttons & BT_ACCELERATE then
			plymo.pull_xy = $+hcombi.cv_combipull.value/2
		end
	if player.cmd.buttons & BT_BRAKE then
		plymo.pull_xy = $+hcombi.cv_combipull.value
	end
	if not P_IsObjectOnGround(plymo) then
		if not has_partner then
			partner.pull_z = 0
			partner.pull_xy = 0
		else
			plymo.pull_z = $+hcombi.cv_combipull.value*2
		end
		plymo.cur_airtime = (plymo.cur_airtime or 0) + 1
		if plymo.cur_airtime - (partner.cur_airtime or 0) > 3*TICRATE then
			hcombi.P_TeleportMobj(plymo, partner.x, partner.y, partner.z + 100*mapscale*P_MobjFlip(partner))
			plymo.cur_airtime = 0
			partner.cur_airtime = 0
		end
	else
		plymo.cur_airtime = 0
			
		if P_IsObjectOnGround(partner) and abs(plymo.z - partner.z) > 200*mapscale then
			partner.pull_z = 0
		end	
	end

	if player.combi ~= nil then
		if partner.player.cmd.buttons & BT_ACCELERATE then
			partner.pull_xy = $+hcombi.cv_combipull.value/2
		end
		if partner.player.cmd.buttons & BT_BRAKE then
			partner.pull_xy = $+hcombi.cv_combipull.value
		end
		if not P_IsObjectOnGround(partner) and partner.pull_z then
			partner.pull_z = $+hcombi.cv_combipull.value*2
		end
				
		if 
		player.kartstuff[k_growshrinktimer] < -2 and partner.player.kartstuff[k_growshrinktimer] >= -2 then
			player.kartstuff[k_growshrinktimer] = -2
		elseif player.kartstuff[k_growshrinktimer] > 0 then
			partner.player.kartstuff[k_growshrinktimer] = max($, player.kartstuff[k_growshrinktimer])
			
			partner.player.mo.destscale = max(player.mo.destscale, $)
			partner.player.mo.scalespeed = max(player.mo.scalespeed, $)
		else
			/* now lives within hugequest itself, so no need for this
			if (HugeQuest
			and CV_FindVar("hq_sparkle").value 
			and player.hugequest.sparkle) then
				partner.player.hugequest.sparkle = $ or 0
				if not partner.player.hugequest.sparkle then
					partner.player.hugequest.sparkle = max($, player.hugequest.sparkle)
				end
			end
			*/ 
		end
		
		for _, prop in ipairs({k_sneakertimer, k_invincibilitytimer, k_driftboost, k_startboost}) do
			player.kartstuff[prop] = max($, partner.player.kartstuff[prop])
		end
		player.realtime = min($, partner.player.realtime)
		-- HQ Super interop, since without this existing causes some timer bugs
		if HugeQuest then
			/* same with this
			if partner.player.hugequest.super and not player.hugequest.super then
				-- sync both so that we dont get any weird side effects
				player.hugequest.huge = partner.player.hugequest.huge
				player.hugequest.sparkle = partner.player.hugequest.sparkle
				player.hugequest.super = 1
				//player.mo.sparkle = max($, players[player.combi].mo.sparkle)
				player.kartstuff[k_invincibilitytimer] = partner.player.kartstuff[k_invincibilitytimer]
				K_PlayPowerGloatSound(player.mo)
				S_ChangeMusic("HQSUPR", true, player)
			end
			*/
		end

		if partner.player.exiting and not player.exiting then
			-- fuck it
			player.pflags = $ & ~PF_TIMEOVER
			player.lives = 1
			player.deadtimer = 0
			player.kartstuff[k_respawn] = 0
			player.exiting = partner.player.exiting
			if not player.mo.signspawned then
				local exitsign = P_SpawnMobj(player.mo.x, player.mo.y, player.mo.z+(mapobjectscale*400),MT_SIGN)
				exitsign.target = player.mo
				exitsign.state = S_SIGN1
				exitsign.movefactor = player.mo.floorz
				exitsign.movecount = 1
				player.mo.signspawned = true
			end
			P_PlayVictorySound(player.mo)
			P_RestoreMusic(player)
		end
	end
end

hcombi.YankRespawnThink = function(player, has_partner)
	local partner = hcombi.ReturnPartner(player, has_partner)
	local plymo = player.mo
	
	local yank_xy = FixedDiv(partner.pull_xy, plymo.pull_xy+partner.pull_xy)/4
	local yank_z = FixedDiv(partner.pull_z, plymo.pull_xy+partner.pull_z)/4
	
	if not has_partner then
		if player.kartstuff[k_respawn] then
			if (not player.combi_respawn) or (player.mo.momz > -3*mapscale and (P_MobjFlip(player.mo) == 1 and player.mo.z - player.mo.floorz > 20*mapscale) or (P_MobjFlip(player.mo) == -1 and player.mo.z - player.mo.ceilingz < -20*mapscale)) then
				local dist = FixedMul(mapscale, 60)
					
				-- Let players shift sideways while respawning if they hold drift?
				if player.cmd.buttons & BT_DRIFT then
					local speed = player.cmd.driftturn/100
					P_TryMove(player.mo, player.mo.x - sin(player.mo.angle)*speed, player.mo.y + cos(player.mo.angle)*speed, true)
				end
				
				player.combi_respawn = true
					
				hcombi.P_TeleportMobj(partner, player.mo.x, player.mo.y, player.mo.z + 100*mapscale*P_MobjFlip(player.mo))
				partner.momx, partner.momy, partner.momz = 0, 0, 0
				partner.angle = player.mo.angle
				
				return
			end
		else
			player.combi_respawn = false
		end
		return
	end
	
	local addi = 100*mapscale
	local addi_p = 100*mapscale
	if player.kartstuff[k_starpostflip] then
		addi = (100*mapscale) * -1
	end
	if partner.player.kartstuff[k_starpostflip] then
		addi_p = (100*mapscale) * -1
	end
	
	-- sync our respawn timer
	player.kartstuff[k_respawn] = max($, partner.player.kartstuff[k_respawn])
	
	if not player.kartstuff[k_respawn] then
		partner.player.kartstuff[k_respawn] = 0
		player.combi_respawn = false 
		partner.player.combi_respawn = false 
	end
	
	if player.kartstuff[k_respawn] and (partner.player.kartstuff[k_respawn] ~= 48 or partner.player.kartstuff[k_respawn] ~= 47) and not partner.player.combi_respawn then
		-- check if we have gotten a starpoint
		-- we need to so that we respawn at the right spot
		if player.starpostnum and player.starpostnum > 0 then
			hcombi.P_TeleportMobj(player.mo, player.starpostx*FRACUNIT, player.starposty*FRACUNIT, (player.starpostz*FRACUNIT) + addi*P_MobjFlip(player.mo))
			player.mo.angle = player.starpostangle
		else
			hcombi.P_TeleportMobj(player.mo, player.startposition[1], player.startposition[2], player.startposition[3] + addi*P_MobjFlip(player.mo))
			player.mo.angle = player.startposition[4]
		end
		-- teleport our partner to where we are
		hcombi.P_TeleportMobj(partner, player.mo.x, player.mo.y, player.mo.z + addi*P_MobjFlip(player.mo))
		-- handle everything else lmao
		HandleRespawnSync(partner, player)
	end
	
	if player.kartstuff[k_respawn] > 1 then
		HandleRespawnSync(partner, player)
	end
	
	if player.deadtimer > 1 then
		if (leveltime % 2) == 0 then
			partner.player.mo.color = SKINCOLOR_RED
			partner.player.mo.colorized = true
		else
			partner.player.mo.color = partner.player.skincolor
			partner.player.mo.colorized = false
		end
	end
	
	if player.kartstuff[k_respawn] == 48 or player.kartstuff[k_respawn] == 47 then
		player.mo.color = player.skincolor
		player.mo.colorized = false
	end
	
	if partner.player.kartstuff[k_respawn] and (player.kartstuff[k_respawn] ~= 48 or player.kartstuff[k_respawn] ~= 47) and not player.combi_respawn then
		-- check if we have gotten a starpoint
		-- we need to so that we respawn at the right spot
		if partner.player.starpostnum and partner.player.starpostnum > 0 then
			hcombi.P_TeleportMobj(partner, partner.player.starpostx*FRACUNIT, partner.player.starposty*FRACUNIT, (partner.player.starpostz*FRACUNIT) + addi_p*P_MobjFlip(partner))
			partner.angle = partner.player.starpostangle
		else
			hcombi.P_TeleportMobj(partner, partner.player.startposition[1], partner.player.startposition[2], partner.player.startposition[3] + addi_p*P_MobjFlip(partner))
			partner.angle = partner.player.startposition[4]
		end
		-- teleport our partner to where we are
		hcombi.P_TeleportMobj(player.mo, partner.x, partner.y, partner.z + addi_p*P_MobjFlip(partner))
		-- handle everything else lmao
		HandleRespawnSync(player.mo, partner.player)
	end
end

