local TICRATE = TICRATE
local HALFTICRATE = TICRATE/2
local PST_LIVE = PST_LIVE
local KITEM_HYUDORO = KITEM_HYUDORO
local k_stolentimer = k_stolentimer
local k_itemblink = k_itemblink
local k_itemtype = k_itemtype
local k_itemamount = k_itemamount
local k_hyudorotimer = k_hyudorotimer
local hostmodload = false

local funny_hyu = CV_RegisterVar({
	name = "funny_hyu",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

local funny_hyu_counter = 0

addHook("NetVars", function(net)
	funny_hyu_counter = net($)
end)

addHook("ThinkFrame", do
	local hyudoroplayer
	if funny_hyu.value
		for p in players.iterate
			if not (p.mo and p.mo.valid)
			or p.spectator then continue end
			p.savedhyutimer = $ or 0
			local ks = p.kartstuff
			if ks[k_stolentimer] and ks[k_stolentimer] > HALFTICRATE-2 
				if (not funny_hyu_counter or P_RandomChance(FRACUNIT - FRACUNIT/(funny_hyu_counter+1)))
					p.funnyhyu = true
					ks[k_itemblink] = HALFTICRATE
					ks[k_itemtype] = KITEM_HYUDORO
					ks[k_itemamount] = 1
					funny_hyu_counter = $+1
					hyudoroplayer = p
				else
					print("The Hyudoro's had its fun, goodbye.")
				end
			elseif ks[k_itemtype] == KITEM_HYUDORO
				hyudoroplayer = p
			elseif not ks[k_hyudorotimer] --No Hyudoro
				p.funnyhyu = false
			end
			if ks[k_hyudorotimer]
				if p.funnyhyu and ks[k_itemtype] ~= KITEM_HYUDORO --We just used our Funny Hyudoro, I think?
					p.funnyhyu = false
					if kmp and kmp_hyudoro.value 
					and not p.k_hyudoroextend
						p.k_hyudoroextend = true --I only want the first Hyudoro use getting the effects of Lat's KartMP
					end
					ks[k_hyudorotimer] = max(7*TICRATE/2, p.savedhyutimer-1) --Everyone else gets the opposite lol
				end
			elseif kmp
				p.k_hyudoroextend = nil
			end
			p.savedhyutimer = ks[k_hyudorotimer]
		end
	end
	if not hyudoroplayer
		funny_hyu_counter = 0
	end
	if hostmodload or not (server and HOSTMOD and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "Funny Hyu", var = "funny_hyu"})
	hostmodload = true
end)