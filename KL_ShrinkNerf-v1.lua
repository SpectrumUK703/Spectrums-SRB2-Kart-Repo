local k_itemtype = k_itemtype
local k_growshrinktimer = k_growshrinktimer
local k_itemamount = k_itemamount
local hostmodload = false

local shrink_nerf = CV_RegisterVar({
	name = "shrink_nerf",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

addHook("ThinkFrame", function()
	if not shrink_nerf.value then return end
	local stripitems = P_RandomChance(FRACUNIT/2)
	for p in players.iterate
		local ks = p.kartstuff
		if ks[k_growshrinktimer] < 0
			if not p.shrinknerfed
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
