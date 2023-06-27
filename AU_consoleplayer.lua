--Copied from Ashnal's Utilities

-- SRB2Kart Lua Script
-- consoleplayer -- Get consoleplayer, secondarydisplayplayer,
-- thirddisplayplayer and fourthdisplayplayer as player_t!
-- These are always valid too, except possibly in a PlayerCmd hook that was
-- added before this script.
--
-- Copyright 2019 James R.
-- You may use this script as you please provided that you preserve the above
-- copyright notice and this text.
--
-- P.S. I want to kiss Lat'

	if        consoleplayer_lua == nil then

rawset (_G, "consoleplayer_lua", true)


local splitplayerids =
{
	"secondarydisplayplayer",
	    "thirddisplayplayer",
	   "fourthdisplayplayer",
}

addHook ("PlayerCmd", function (p)
	if (p.splitscreenindex == 0)
	then
		rawset (_G, "consoleplayer", p)
		-- Erase invalidated splitplayers from leaving netgames.
		for i = 1, 3
		do
			if _G[splitplayerids[i]] ~= nil and
				(not _G[splitplayerids[i]].valid) then _G[splitplayerids[i]] = nil
			end
		end
	else
		rawset (_G, splitplayerids[p.splitscreenindex], p)
	end
end)

	end -- consoleplayer_lua
	
-- the above is valid but i want to die
-- TyroneSama 2019