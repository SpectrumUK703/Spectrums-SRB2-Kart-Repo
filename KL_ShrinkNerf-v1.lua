local k_itemtype = k_itemtype
local k_growshrinktimer = k_growshrinktimer
local k_itemamount = k_itemamount
local k_position = k_position
local hostmodload = false

local shrink_nerf = CV_RegisterVar({
	name = "shrink_nerf",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

addHook("ThinkFrame", function()
	if leveltime < TICRATE or G_BattleGametype() or not shrink_nerf.value
		for p in players.iterate
			p.shrinknerfed = true
			p.shrinknerfsaveditem = {}
		end
		return
	end
	local playercount
	for p in players.iterate
		if p.mo and p.mo.valid and not p.spectator
			playercount = $ and $+1 or 1
		else
			p.shrinknerfed = true
			p.shrinknerfsaveditem = {}
		end
	end
	local stripitems = P_RandomChance(FRACUNIT/2)
	for p in players.iterate
		local ks = p.kartstuff
		if ks[k_growshrinktimer] < 0
			if ks[k_position]-1 <= playercount/5
				p.shrinknerfed = true
			elseif not p.shrinknerfed
				if stripitems
					ks[k_growshrinktimer] = -1
				else
					if p.shrinknerfsaveditem and p.shrinknerfsaveditem[1] and p.shrinknerfsaveditem[2]
						ks[k_itemtype] = p.shrinknerfsaveditem[1]
						ks[k_itemamount] = p.shrinknerfsaveditem[2]
					end
				end
				p.shrinknerfed = true
			end
		else
			p.shrinknerfed = false
		end
		p.shrinknerfsaveditem = {ks[k_itemtype], ks[k_itemamount]}
	end
	if hostmodload or not (server and HOSTMOD and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "Shrink Nerf", var = "shrink_nerf"})
	hostmodload = true
end)
