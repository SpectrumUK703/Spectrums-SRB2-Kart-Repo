local TICRATE = TICRATE
local HALFTICRATE = TICRATE/2
local PST_LIVE = PST_LIVE
local KITEM_HYUDORO = KITEM_HYUDORO
local k_stolentimer = k_stolentimer
local k_itemblink = k_itemblink
local k_itemtype = k_itemtype
local k_itemamount = k_itemamount
local hostmodload = false


local funny_hyu = CV_RegisterVar({
	name = "funny_hyu",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

local funny_hyu_debug = CV_RegisterVar({
	name = "funny_hyu_debug",
	defaultvalue = "Off",
	possiblevalue = CV_OnOff
})

local funny_hyu_counter = 0

addHook("NetVars", function(net)
	funny_hyu_counter = net($)
end)

addHook("ThinkFrame", do
	local hyudoroplayer
	for p in players.iterate
		if not (p.mo and p.mo.valid)
		or p.spectator
		or p.playerstate != PST_LIVE then continue end
		local ks = p.kartstuff
		if funny_hyu.value and ks[k_stolentimer] and ks[k_stolentimer] > HALFTICRATE-2 
		and (not funny_hyu_counter or P_RandomChance(FRACUNIT - FRACUNIT/(funny_hyu_counter+1)))
			ks[k_itemblink] = HALFTICRATE
			ks[k_itemtype] = KITEM_HYUDORO
			ks[k_itemamount] = 1
			funny_hyu_counter = $+1
			hyudoroplayer = p
			if funny_hyu_debug.value
				print("funny_hyu_counter: "..funny_hyu_counter)
			end
			break
		elseif ks[k_itemtype] == KITEM_HYUDORO
			hyudoroplayer = p
			break
		end
	end
	if not hyudoroplayer
		funny_hyu_counter = 0
	end
	if hostmodload or not (server and HOSTMOD and CV_FindVar("hm_scoreboard") and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "Funny Hyu", var = "funny_hyu"})
	hostmodload = true
end)