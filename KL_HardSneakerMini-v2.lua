-- maps aren't made for a 50% speed boost on hard, but...
local k_sneakertimer = k_sneakertimer
local k_speedboost = k_speedboost
local hostmodload

local hardsneakermini = CV_RegisterVar({
    name = "hardsneakermini",
    defaultvalue = "On",
    possiblevalue = CV_OnOff,
    flags = CV_NETVAR,
})

addHook("ThinkFrame", do
	if not hardsneakermini.value then return end
	for p in players.iterate do
		if not (p.mo and p.mo.valid) or p.spectator then continue end
		if p.kartstuff[k_sneakertimer]
			p.kartstuff[k_speedboost] = max($, 24576)	-- invincibility speed
		end
	end
	if hostmodload or not (server and HOSTMOD and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "HardSneakerMini", var = "hardsneakermini"})
	hostmodload = true
end)
