local k_itemtype = k_itemtype
local TICRATE = TICRATE
local snapblasterid

addHook("ThinkFrame", function()
	if not xItemLib then return end
	if not snapblasterid
		snapblasterid = xItemLib.xItemNamespaces["XITEM_SNAPBLASTER"]
	end
	for p in players.iterate
		if p.kartstuff[k_itemtype] == snapblasterid
			if not p.cbl	-- If we stole a Chameleon Blaster with Hyudoro, set it up
				p.cbl = {timer = (10*TICRATE), rounds = 7, reload = false ,cooldown = 0}
			end
		elseif p.cbl	-- If we lost a Chameleon Blaster to a Hyudoro, undo its setup
			p.cbl = nil
		end
	end
end)

-- This probably doesn't actually need to be NetVar'd, but just in case
addHook("NetVars", function(net)
	snapblasterid = net($)
end)