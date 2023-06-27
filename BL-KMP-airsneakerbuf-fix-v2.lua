--I originally made this an edit of BoostLib. Don't add this with Juicebox though, fixing that issue does require editing BoostLib.
local FRACUNIT = FRACUNIT
local TICRATE = TICRATE
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
local k_spinouttimer = k_spinouttimer

local prefix = "blib_"

local section, special = 2, 6 -- for the map specific panels
local vanillasneakertime = 47
local gamespeedsneakerstrength = { 53740+768, 32768, 17294+768}
local starttime = 6*TICRATE + (3*TICRATE/4)
local player, tempsneakerstrength

local cv_panelstack = CV_FindVar(prefix.."panelstack")

local K_DoSneaker_Vanilla = K_DoSneaker

rawset(_G, "K_DoSneaker", function(p)
	local mo = p.mo
	local pks = p.kartstuff
	if BLib and mo and mo.valid
		if P_PlayerTouchingSectorSpecial(p, section, special) then  -- for the map specific panels
			mo.stackedpanels = min(($ or 0)+1, 3)
		else
			mo.stackedpanels = min(($ or 0)+1,cv_panelstack.value)
		end
		mo.resetboostflame = true
		mo.naturalpanelsneakertimer = vanillasneakertime
		pks[k_sneakertimer] = vanillasneakertime
		mo.panelsneakertimer = max(BLib.BoostChain(p, "panelsneaker", vanillasneakertime), vanillasneakertime) + 1
	end
	return K_DoSneaker_Vanilla(p)
end)

addHook("ThinkFrame", do
	if not BLib then return end
	cv_panelstack = $ or CV_FindVar(prefix.."panelstack")
end)