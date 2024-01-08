--item flags, people making custom items can copy/paste this over to their lua scripts
local XIF_POWERITEM = 1 --is power item (affects final odds)
local XIF_COOLDOWNONSTART = 2 --can't be obtained on start cooldown
local XIF_UNIQUE = 4 --only one can exist in anyone's slot
local XIF_LOCKONUSE = 8 --locks the item slot when the item is used, slot must be unlocked manually by setting player.xItemData.xItem_itemSlotLocked to false
local XIF_COOLDOWNINDIRECT = 16 --checks if indirectitemcooldown is 0
local XIF_COLPATCH2PLAYER = 32 --map hud patch colour to player prefcolor
local XIF_ICONFORAMT = 64 --item icon and dropped item frame changes depending on the item amount (animation frames become amount frames)
local XIF_SMUGGLECHECK = 128 --item contributes to the smuggle detection

--apparently this makes shit faster? wtf?
local TICRATE = TICRATE
local FRACUNIT = FRACUNIT
local MAXSKINCOLORS = MAXSKINCOLORS
local ANG1 = ANG1
local k_sneakertimer = k_sneakertimer
local k_spinouttimer = k_spinouttimer
local k_wipeoutslow = k_wipeoutslow
local k_driftboost = k_driftboost
local k_floorboost = k_floorboost
local k_startboost = k_startboost
local k_itemamount = k_itemamount
local k_itemtype = k_itemtype
local k_rocketsneakertimer = k_rocketsneakertimer
local k_hyudorotimer = k_hyudorotimer
local k_drift = k_drift
local k_speedboost = k_speedboost
local k_accelboost = k_accelboost
local k_invincibilitytimer = k_invincibilitytimer
local k_growshrinktimer = k_growshrinktimer
local k_driftcharge = k_driftcharge
local k_position = k_position
local k_roulettetype = k_roulettetype
local k_itemroulette = k_itemroulette
local k_bumper = k_bumper
local k_eggmanheld = k_eggmanheld
local k_itemheld = k_itemheld
local k_squishedtimer = k_squishedtimer
local k_respawn = k_respawn
local k_stolentimer = k_stolentimer
local k_stealingtimer = k_stealingtimer

--desperate times call for desperate measures
local FixedMul = FixedMul
local FixedDiv = FixedDiv
local R_PointToDist2 = R_PointToDist2
local type = type
local table = table
local pcall = pcall
local min = min
local max = max

rawset(_G, "smuggleDetection", function()
	local group = {}
	local itemData = {}
	local itemFlags = 0
	for p in players.iterate
		if not p.spectator then
			table.insert(group, p)
		end
	end
	
	for i=1, #group
		itemFlags = 0
		if group[i].kartstuff[k_itemtype] then
			itemData = xItemLib.func.getItemDataById(group[i].kartstuff[k_itemtype])
			if itemData then
				itemFlags = itemData.flags
			end
		end
		if 
			group[i].kartstuff[k_position] <= 2
			and (
				(itemFlags and (itemFlags & XIF_SMUGGLECHECK))
				or group[i].kartstuff[k_invincibilitytimer] > 0
				or group[i].kartstuff[k_growshrinktimer] > 0
				or (HugeQuest and group[i].hugequest.huge > 0)
			)
		then
			--print("SMUGGLER DETECTED")
			return true
		end
	end

	return false
end)