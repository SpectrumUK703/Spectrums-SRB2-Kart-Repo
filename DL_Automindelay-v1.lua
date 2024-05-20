local mindelay = CV_FindVar("mindelay")
local preferredmindelay

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
	if automindelay.value == 0 or (consoleplayer == server and automindelay.value == 1) then
		preferredmindelay = mindelay.value
		return
	end
	if not (netgame and consoleplayer) or consoleplayer.spectator then
		return 
	end
	local numplayers = 0
	local lowestping = 15
	local highestping = 0
	local totalping = 0
	for p in players.iterate
		if p.spectator or p.bot then continue end
		if p ~= consoleplayer then
			numplayers = $+1
			lowestping = min($, p.ping)
			highestping = max($, p.ping)
		end
		totalping = $+p.ping
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
			if mindelay.value ~= highestping
				COM_BufInsertText(consoleplayer, "mindelay "..tostring(highestping))
			end
		else
			totalping = $-min(lowestping, consoleplayer.ping)	-- take away the lowest ping
			local averageping = totalping/numplayers
			averageping = max(min($, 15), 0)
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