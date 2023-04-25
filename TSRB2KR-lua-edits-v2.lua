if not tsrb2kr then return end

local TICRATE = TICRATE
local FRACUNIT = FRACUNIT
--local ANGLE_22h = ANGLE_22h
--local FRACBITS = FRACBITS
local k_sneakertimer = k_sneakertimer
local k_spinouttimer = k_spinouttimer
local k_wipeoutslow = k_wipeoutslow
local k_driftboost = k_driftboost
local k_driftcharge = k_driftcharge
local k_floorboost = k_floorboost
local k_startboost = k_startboost
local k_itemamount = k_itemamount
local k_itemtype = k_itemtype
local k_rocketsneakertimer = k_rocketsneakertimer
local k_hyudorotimer = k_hyudorotimer
local k_drift = k_drift
local k_speedboost = k_speedboost
local k_boostpower = k_boostpower
local k_accelboost = k_accelboost
local k_invincibilitytimer = k_invincibilitytimer
local k_growshrinktimer = k_growshrinktimer
local k_offroad = k_offroad
local k_itemroulette = k_itemroulette
local k_roulettetype = k_roulettetype
local STARTTIME = 6*TICRATE + (3*TICRATE/4)

-- KartMP
rawset(_G, "tsr_ultimatemusic", tsrb2kr)

-- Egg Panic
tsrb2kr.HUD_DrawItems = function(v, p)
	-- splitscreen makes me want to commit die: the sequel
	-- now with a threequel
	local x, y = 265, 5
	if (splitscreen)
		x, y = 270, -1
		if ((splitscreen) > 1)
			x, y = 121, -8
		end
	end

	local scale = ((splitscreen) == 1) and FRACUNIT*5/7 or FRACUNIT
	local scaleShift = 0
	if ((splitscreen) == 1)
		scaleShift = 6
	end

	--local transferring = (server.tsr_transfers[p.tsr_team][2] == p)
	local transferring = false
	local flags = tsrb2kr.ReturnSplitFlags(V_SNAPTORIGHT|V_SNAPTOTOP|V_HUDTRANS, tsrb2kr.IsDisplayPlayer(p))

	v.draw(x, y, v.cachePatch("K_TSRBG"..((splitscreen) and ((splitscreen) > 1 and 3 or 2) or 1)), flags, v.getColormap(-1, tsrb2kr.ReturnTeamColor(p.tsr.team)))

	local itemPatchs = {"K_ITSHOE", "K_ITBANA", "K_ITORB1", "K_ITMINE", "K_ITGROW", "K_ITHYUD", "K_ITRSHE", "K_ITJAWZ", "K_ITSPB", "K_ITSHRK", "K_ITINV"..leveltime%21/3+1, "K_ITEGGM", "K_ITBHOG", "K_ITTHNS"}
	if ((splitscreen) > 1)
		itemPatchs = {"K_ISSHOE", "K_ISBANA", "K_ISORBN", "K_ISMINE", "K_ISGROW", "K_ISHYUD", "K_ISRSHE", "K_ISJAWZ", "K_ISSPB", "K_ISSHRK", "K_ISINV"..leveltime%18/3+1, "K_ISEGGM", "K_ISBHOG", "K_ISTHNS"}
	end

	if (p.kartstuff[k_itemroulette])
		v.drawScaled((x+scaleShift)<<FRACBITS, (y+scaleShift)<<FRACBITS, scale, v.cachePatch(itemPatchs[p.kartstuff[k_itemroulette]%42/3+1]), flags, v.getColormap(TC_RAINBOW, p.skincolor))
	end

	local blinkColours = {SKINCOLOR_RED, leveltime%SKINCOLOR_LILAC+1}

	if (p.kartstuff[k_itemtype])
		local numberPatches = {"K_ITSHOE", "K_ITRSHE", "K_ITINV"..leveltime%21/3+1, "K_ITBANA", "K_ITEGGM", "K_ITORB"..max(1, min(4, p.kartstuff[k_itemamount])), "K_ITJAWZ", "K_ITMINE", "K_ITBHOG", "K_ITSPB", "K_ITGROW", "K_ITSHRK", "K_ITTHNS", "K_ITHYUD", "K_ITPOGO", "K_ITSINK"}
		if ((splitscreen) > 1)
			numberPatches = {"K_ISSHOE", "K_ISRSHE", "K_ISINV"..leveltime%18/3+1, "K_ISBANA", "K_ISEGGM", "K_ISORBN", "K_ISJAWZ", "K_ISMINE", "K_ISBHOG", "K_ISSPB", "K_ISGROW", "K_ISSHRK", "K_ISTHNS", "K_ISHYUD", "K_ISPOGO", "K_ISSINK"}
		end

		-- multiple item overlay
		if (p.kartstuff[k_itemamount] > 1 and not (not (splitscreen > 1) and (p.kartstuff[k_itemtype] == KITEM_ORBINAUT and p.kartstuff[k_itemamount] < 5)))
			local pp = v.cachePatch(splitscreen and (splitscreen > 1 and "K_ISMUL" or "K_TSRML2") or "K_TSRML1")

			local flipflag, flipshift = 0, 0
			if ((splitscreen > 1))
				flipflag, flipshift = V_FLIP, (pp.width)-1
			end
			v.draw(x+flipshift, y, pp, flipflag|flags)
		end
		-- the item
		if not ((p.kartstuff[k_itemheld] or transferring) and leveltime%2) and not (p.kartstuff[k_stealingtimer] > 0 and leveltime%3) then v.drawScaled((x+scaleShift)<<FRACBITS, (y+scaleShift)<<FRACBITS, (splitscreen) == 1 and FRACUNIT*5/7 or FRACUNIT, v.cachePatch(numberPatches[p.kartstuff[k_itemtype]] or "K_ITSAD"), flags, v.getColormap((p.kartstuff[k_itemblink] and leveltime%2) and -6 or -1, (p.kartstuff[k_itemblink] and leveltime%2) and (blinkColours[p.kartstuff[k_itemblinkmode]] or SKINCOLOR_WHITE) or SKINCOLOR_NONE)) end
		-- how much of the item
		if (p.kartstuff[k_itemamount] > 1)
			if not (not (splitscreen > 1) and (p.kartstuff[k_itemtype] == KITEM_ORBINAUT and p.kartstuff[k_itemamount] < 5))
				if ((splitscreen) > 1)
					v.drawString(x+2, y+31, "x"..p.kartstuff[k_itemamount], flags|V_ALLOWLOWERCASE)
				else
					local coords = (splitscreen) and {x-1, y+36} or {x-7, y+41}

					v.draw(coords[1], coords[2], v.cachePatch("K_ITX"), flags)
					tsrb2kr.DrawMKText(v, p.kartstuff[k_itemamount], coords[1]+10, coords[2]-5, flags, "left")
				end
			end
		end
	end

	-- flashing icons and timer bars (EXTREMELY optimized)
	local timerChecks = {
		{{k_stealingtimer, "HYUD", 3}, {k_stolentimer, "HYUD", 3}, {k_sadtimer, "SAD", 3}, {k_growshrinktimer, "GROW", 2, {k_growcancel, 26}}}, -- > 0 timers
		{{k_eggmanexplode, "EGGM", 2}, {k_rocketsneakertimer, "RSHE", 2, {k_rocketsneakertimer, 814}}} -- > 1 timers
	}

	for t = 1, 2
		for i = 1, #timerChecks[t]
			local c = timerChecks[t][i]
			-- flashing icons
			if (p.kartstuff[c[1]] > (t-1) and leveltime%c[3])
				v.drawScaled((x+scaleShift)<<FRACBITS, (y+scaleShift)<<FRACBITS, scale, v.cachePatch("K_I"..(splitscreen > 1 and "S" or "T")..timerChecks[t][i][2]), flags)
			end

			-- 265, 5
			-- 276, 40
			-- timer bars
			if c[4] and p.kartstuff[c[4][1]] > 0
				local coords = {x+11, y+35}
				if (splitscreen)
					coords = {x+14, y+31}
					if ((splitscreen) > 1)
						coords = {x+17, y+27}
					end
				end

				-- main bar
				v.draw(coords[1], coords[2], v.cachePatch(splitscreen and (splitscreen > 1 and "K_ISIMER" or "K_TSRMER") or "K_ITIMER"), flags)

				-- borders
				local length = (splitscreen and (splitscreen > 1 and 12 or 19) or 26)

				v.drawFill(coords[1]+1, coords[2]+1, p.kartstuff[c[4][1]]*length/c[4][2], 1, 120|flags)
				if not (splitscreen > 1) then v.drawFill(coords[1]+1, coords[2]+2, p.kartstuff[c[4][1]]*length/c[4][2], 1, 8|flags) end
				v.drawFill(coords[1]+1, coords[2]+1, 1, (splitscreen > 1 and 1 or 2), 12|flags)
				if (p.kartstuff[c[4][1]]*length/c[4][2] > 0) then v.drawFill(coords[1]+p.kartstuff[c[4][1]]*length/c[4][2], coords[2]+1, 1, (splitscreen > 1 and 1 or 2), 12|flags) end
			end
		end
	end

	-- special case: eggbox timer
	if (p.kartstuff[k_eggmanexplode] > 1)
		local egglimit = (eggpanic and 5) or 3
		v.draw(x+(splitscreen > 1 and 16 or 17), y+(splitscreen > 1 and 11 or 13), v.cachePatch("K_EGGN"..min(egglimit, G_TicsToSeconds(p.kartstuff[k_eggmanexplode]))), flags)
	end

	-- p1's stored item:
	if (p.tsr.storeditem)
	and (leveltime%8) >= 4
		local hx, hy, scale = x+4, y+53, FRACUNIT/4
		if (splitscreen)
			hx, hy, scale = x+8, y+47, FRACUNIT/5
			if (splitscreen > 1)
				hx, hy, scale = x+14, y+34, FRACUNIT/6
			end
		end

		v.drawScaled(hx<<FRACBITS, hy<<FRACBITS, scale, v.cachePatch("RNDMA0"), flags)
	end
end

tsrb2kr.Framework_ColourItems = function()
	if not (server.tsr_server.colouritems and #server.tsr_server.colouritems) then return end

	local i = #server.tsr_server.colouritems
	while i
		local mo = server.tsr_server.colouritems[i]

		-- check if mo is still valid
		if not (mo and mo.valid) or not mo.health
			table.remove(server.tsr_server.colouritems, i)
			i = $-1
			continue
		end

		-- now colour the item
		-- Make sure to check if the item was thrown by a player
		if (mo.target and mo.target.player and mo.target.player.tsr.team)
			-- needs to be on a team
			if not (mo.target.player.tsr.team)
				i = $-1
				continue
			end
			
			-- spawn a marker on them if they dont have one already (not for shield items)
			local noMarker = false
			local noMarkerTypes = {MT_BANANA_SHIELD, MT_ORBINAUT_SHIELD, MT_EGGMANITEM_SHIELD, MT_JAWZ_SHIELD, MT_SSMINE}
			for item = 1, #noMarkerTypes
				if (mo.type == noMarkerTypes[item]) then noMarker = true end
			end

			if not (mo.tsr_HImarker and mo.tsr_HImarker.valid) and not noMarker
				mo.tsr_HImarker = P_SpawnMobj(mo.x, mo.y, mo.z, MT_TSR_HIGHLIGHTITEM)
				mo.tsr_HImarker.target = mo
				mo.tsr_HImarker.color = tsrb2kr.ReturnTeamColor(mo.target.player.tsr.team)
				mo.tsr_HImarker.flags2 = $|MF2_DONTDRAW
			end

			-- make sure bananas, eggboxes, jawz and ballhogs are coloured, too
			local teamSprites = {
				-- Bananas
				[MT_BANANA] = SPR_TBNA,
				[MT_BANANA_SHIELD] = SPR_TBNA,
				-- Jawz
				[MT_JAWZ] = SPR_TJWZ,
				[MT_JAWZ_DUD] = SPR_TJWZ,
				[MT_JAWZ_SHIELD] = SPR_TJWZ,
				-- Ballhog
				[MT_BALLHOG] = SPR_THOG
			}
			mo.sprite = teamSprites[mo.type] or states[mo.state].sprite

			mo.color = tsrb2kr.ReturnTeamColor(mo.target.player.tsr.team)
		else
			-- reset sprite
			mo.sprite = states[mo.state].sprite
		end

		-- go to next item in the table
		i = $-1
	end
end

freeslot("S_RSPB_SPB2", "S_RSPB_SPB3")

states[S_RSPB_SPB2] = {SPR_THOK, A, -1, A_SPBChase, 0, 0, S_RSPB_SPB3}
states[S_RSPB_SPB3] = {SPR_THOK, A, -1, A_SPBChase, 0, 0, S_RSPB_SPB2}

addHook("MobjThinker", function(mo)
	if not (rspb and CV_FindVar("rspb_enable").value) then return end
	if mo.rspb_rnum and rspb.replacementtable[mo.rspb_rnum]
		local spbinfo = rspb.replacementtable[mo.rspb_rnum]
		mo.state = (mo.state == S_RSPB_SPB2) and S_RSPB_SPB3 or S_RSPB_SPB2 --Alternating states to call A_SPBChase every tic without conflicting with TSR
		mo.sprite = spbinfo.sprite
		mo.frame = spbinfo.frames[(mo.rspb_timer % #spbinfo.frames) + 1]
		mo.rspb_timer = $ + 1
	end
end, MT_SPB)

