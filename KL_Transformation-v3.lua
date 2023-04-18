local use = "sonic"

freeslot (
	"SPR_SUPR",
	"S_HQSSONIC_SIGN" -- Rename this however you want, so long as it isn't the name of another existing state.
) 
-- Shoutouts to KamiJoJo for making Super Sonic reusable, thereby making this specific transformation possible

addHook("MusicChange", function(oldname, newname, mflags, looping) -- Feel free to delete this hook if you aren't setting custom Super music.
	for dp in displayplayers.iterate
		if not (dp.mo and dp.mo.valid) then continue end
		if dp.mo.skin == user then
			if dp.hugequest.super then
				if oldname == "sonsp1" -- Replace with your custom lump
				and (newname == "kgrow" or newname == "kinvnc" or newname == "hqsupr" or newname == "sonsp2")
					return true
				elseif oldname == "sonsp2"
				and (newname == "kgrow" or newname == "kinvnc" or newname == "hqsupr" or newname == "sonsp1")
					return true
				end
			else
				if oldname == "kgrow"
				and (HugeQuest and hq_allsuper.value)
					if P_RandomChance(FRACUNIT/2) then
						return "sonsp1", flags, true
					else
						return "sonsp2", flags, true
					end
				end
			end
		end
	end
end)

-- Custom Overlay state
states[S_HQSSONIC_SIGN] = {
	sprite = SPR_SUPR,
	frame = S,
	tics = -1,
	var1 = 0,
	var2 = 24
}

-- Assign custom Glow Color here
addHook("MobjThinker", function(mo)
	if not (mo and mo.valid and mo.player) then return end
	
	if mo.skin == use
	and not mo.hqassignedcolor then
		mo.hqsupernumber = 9 -- Set your own glow color here
		mo.hqassignedcolor = true
		/*
		Glow colors
		0: Gold
		1: Orange
		2: Red
		3: Pink
		4: Blue
		5: Aqua
		6: Green
		7: White
		8: Bronze
		9: Hyper
		*/
	end
end, MT_PLAYER)

addHook("ThinkFrame", function()
	if leveltime < 2 then return end
	for p in players.iterate
		if not (p.mo and p.mo.valid) then continue end
		if (p.mo.skin == use) then
			p.hugequest.superrank = "SUPRRANK"
			if p.hugequest.super then
				p.mo.sprite = SPR_SUPR -- Replace with your secondary sprite set
		--Music Block, feel feel to delete/comment out if you aren't setting custom music--	
				if not p.mo.hqtrans
					if P_RandomChance(FRACUNIT/2) then
						S_ChangeMusic("sonsp1", true, p) -- Replace with your custom lump
					else
						S_ChangeMusic("sonsp2", true, p)
					end
					p.mo.hqtrans = true
				end
			else
				if p.mo.hqtrans
					p.mo.hqtrans = nil
				end
		--End Music Block--
			end
		end
	end
end)

addHook("MobjThinker", function(mo)-- Custom goalpost stuff
	if not (mo and mo.valid) then return end
	if mo.state == S_PLAY_SIGN
	and (mo.target.target and mo.target.target.player and mo.target.target.skin == use)
		if mo.hqsupergoalset
		and mo.target.target.player.hqsuperfinish then -- Sanity check
			mo.state = S_HQSSONIC_SIGN
			--print("State: "..mo.state)
		end
	end
end, MT_OVERLAY)