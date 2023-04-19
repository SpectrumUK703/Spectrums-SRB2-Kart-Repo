--I originally made this an edit of BoostLib. Don't add this with Juicebox though, fixing that issue does require editing BoostLib.
local FRACUNIT = FRACUNIT
local BT_BRAKE = BT_BRAKE
local KITEM_SNEAKER = KITEM_SNEAKER
local k_startboost = k_startboost
local k_driftboost = k_driftboost
local k_invincibilitytimer = k_invincibilitytimer
local k_growshrinktimer = k_growshrinktimer
local k_sneakertimer = k_sneakertimer
local k_itemtype = k_itemtype
local k_itemamount = k_itemamount
local k_driftcharge = k_driftcharge
local k_rocketsneakertimer = k_rocketsneakertimer
local k_floorboost = k_floorboost

local prefix = "blib_"

local section, special = 2, 6 -- for the map specific panels
local vanillasneakertime = 47
local gamespeedsneakerstrength = { 53740+768, 32768, 17294+768}
local starttime = 6*TICRATE + (3*TICRATE/4)
local function playermobjthinker(mo)
	if not BLib then return end
	local cv_sneakerstack = CV_FindVar(prefix.."sneakerstack")
	local player = mo.player
	local pks = mo.player.kartstuff
	if kmp and kmp_airsneakerbuf.value and mo.kmp_sneakerbuffer and
	P_IsObjectOnGround(mo) and not pks[k_spinouttimer] then
		mo.naturalitemsneakertimer = vanillasneakertime
		pks[k_sneakertimer] = vanillasneakertime
		mo.itemsneakertimer = max(BLib.BoostChain(player, "itemsneaker", vanillasneakertime), vanillasneakertime) + 1
		mo.stackedsneakers = min(($ or 0)+1,cv_sneakerstack.value)
		if (pks[k_rocketsneakertimer] < (mo.BLlastframerocketsneakertimer or 0)-1) then
			mo.stackedrockets = min(($ or 0)+1,cv_sneakerstack.value)
			if mo.hnext then 
				mo.hnext.resetboostflame = true
				if mo.hnext.hnext then mo.hnext.hnext.resetboostflame = true end
			end
		else
			mo.resetboostflame = true
		end
	end
end

addHook("ThinkFrame", do
	for p in players.iterate
		if p.mo and p.mo.valid
			playermobjthinker(p.mo)
		end
	end
end)