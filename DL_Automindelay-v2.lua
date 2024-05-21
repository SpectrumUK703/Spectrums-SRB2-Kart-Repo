local mindelay = CV_FindVar("mindelay")
local preferredmindelay
local numplayers
local lowestping
local highestping
local totalping
local averageping
local ping

local automindelay = CV_RegisterVar({
	name = "automindelay",
	defaultvalue = "Off",
	possibleValue = {Off=0, ["Lowest ping"]=1, ["Average ping"]=2, ["Highest ping"]=3},
	flags = CV_NOINIT|CV_CALL,
	func = function(var)
		mindelay = $ or CV_FindVar("mindelay")
		if mindelay and (var.value == 0 or (consoleplayer == server and var.value == 1)) and preferredmindelay ~= nil and mindelay.value ~= preferredmindelay
			COM_BufInsertText(consoleplayer, "mindelay "..tostring(preferredmindelay))
		end
	end,
	description = "Automatically sets mindelay based on the ping of other players."
})

addHook("ThinkFrame", function()
	mindelay = $ or CV_FindVar("mindelay")
	if not mindelay then return end
	if preferredmindelay == nil
		preferredmindelay = mindelay.value
	end
	if not automindelay.value or (consoleplayer == server and automindelay.value == 1) then
		preferredmindelay = mindelay.value
		return
	end
	if not (netgame and consoleplayer) or consoleplayer.spectator then
		return 
	end
	numplayers = 0
	lowestping = 15
	highestping = 0
	totalping = 0
	for p in players.iterate
		if p.spectator or p.bot then continue end
		ping = p.ping
		if p ~= consoleplayer then
			numplayers = $+1
			if lowestping
				lowestping = min($, ping)
			end
			if highestping < 15
				highestping = max($, ping)
			end
		end
		totalping = $+ping
	end
	if not numplayers then
		return
	elseif numplayers == 1 then
		if consoleplayer ~= server and mindelay.value ~= lowestping
			COM_BufInsertText(consoleplayer, "mindelay "..tostring(lowestping))
		end
	else
		if automindelay.value == 1
			if mindelay.value ~= lowestping
				COM_BufInsertText(consoleplayer, "mindelay "..tostring(lowestping))
			end
		elseif automindelay.value == 3
			highestping = min($, 15)
			if mindelay.value ~= highestping
				COM_BufInsertText(consoleplayer, "mindelay "..tostring(highestping))
			end
		else
			totalping = $-min(lowestping, consoleplayer.ping)	-- take away the lowest ping
			averageping = totalping/numplayers
			averageping = min($, 15)
			if mindelay.value ~= averageping
				COM_BufInsertText(consoleplayer, "mindelay "..tostring(averageping))
			end
		end
	end
end)

addHook("PlayerQuit", function(p)
	if p ~= consoleplayer or preferredmindelay == nil then return end
	mindelay = $ or CV_FindVar("mindelay")
	if not mindelay or preferredmindelay == mindelay.value then return end
	COM_BufInsertText(consoleplayer, "mindelay "..tostring(preferredmindelay))
end)