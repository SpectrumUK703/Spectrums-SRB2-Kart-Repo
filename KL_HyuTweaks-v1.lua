-- Protects players behind a Hyudoro holder from Hyudoro
-- Throwing FunnyHyu in here because lolll
local TICRATE = TICRATE
local HALFTICRATE = TICRATE/2
local KITEM_HYUDORO = KITEM_HYUDORO
local KITEM_SNEAKER = KITEM_SNEAKER
local KITEM_ROCKETSNEAKER = KITEM_ROCKETSNEAKER
local k_stolentimer = k_stolentimer
local k_itemtype = k_itemtype
local k_itemamount = k_itemamount
local k_hyudorotimer = k_hyudorotimer
local k_position = k_position
local k_itemblink = k_itemblink
local TICRATE = TICRATE
local hostmodload

local hyudorotweak = CV_RegisterVar({
    name = "hyudorotweak",
    defaultvalue = "On",
    possiblevalue = CV_OnOff,
    flags = CV_NETVAR,
})

local funny_hyu_counter = 0

addHook("NetVars", function(net)
	funny_hyu_counter = net($)
end)

addHook("ThinkFrame", do
	if not hyudorotweak.value then
		funny_hyu_counter = 0
		return 
	end
	local ks
	local besthyupos
	for p in players.iterate do
		if not (p.mo and p.mo.valid) or p.spectator then continue end
		ks = p.kartstuff
		if ks[k_stolentimer] and ks[k_stolentimer] > HALFTICRATE-2
		and not (JUICEBOX and JUICEBOX.value and (p.hyutweaksaveditem == KITEM_SNEAKER or p.hyutweaksaveditem == KITEM_ROCKETSNEAKER))-- Don't do anything if Juicebox is doing its thing
			if (not funny_hyu_counter or P_RandomChance(FRACUNIT - FRACUNIT/(funny_hyu_counter+1)))
				p.funnyhyu = true
				ks[k_itemblink] = HALFTICRATE
				ks[k_itemtype] = KITEM_HYUDORO
				ks[k_itemamount] = 1
				funny_hyu_counter = $+1
				besthyupos = $ or ks[k_position]
				if ks[k_position] < besthyupos
					besthyupos = ks[k_position]
				end
			else
				p.funnyhyu = false
				print("The Hyudoro's had its fun, goodbye.")
			end
		elseif ks[k_itemtype] == KITEM_HYUDORO
			besthyupos = $ or ks[k_position]
			if ks[k_position] < besthyupos
				besthyupos = ks[k_position]
			end
		elseif not ks[k_hyudorotimer] --No Hyudoro
			p.funnyhyu = false
		end
		if ks[k_hyudorotimer]
			if p.funnyhyu and ks[k_itemtype] ~= KITEM_HYUDORO and p.hyutweaksaveditem == KITEM_HYUDORO --We just used our Funny Hyudoro, I think?
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
		p.hyutweaksaveditem = ks[k_itemtype]
		p.savedhyutimer = ks[k_hyudorotimer]
	end
	if besthyupos
		for p in players.iterate do
			if not (p.mo and p.mo.valid) or p.spectator then continue end
			ks = p.kartstuff
			if ks[k_position] > besthyupos
				ks[k_itemblink] = max($, 2)
			end
		end
	else
		funny_hyu_counter = 0
	end
	if hostmodload or not (server and HOSTMOD and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "HyudoroTweak", var = "hyudorotweak"})
	hostmodload = true
end)
