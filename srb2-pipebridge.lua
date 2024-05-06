local function RGBtoHSV(rgb)
	local M = rgb[1]
	if M < rgb[2]
		M = rgb[2]
	end
	if M < rgb[3]
		M = rgb[3]
	end
	local m = rgb[1]
	if m > rgb[2]
		m = rgb[2]
	end
	if m > rgb[3]
		m = rgb[3]
	end
	if M == m
		return { 0, 0, M * 100 / 15 }
	end
	local c = M - m
	local s = (c * 100) / M
	local R = ((M - rgb[1]) << 12) / c
	local G = ((M - rgb[2]) << 12) / c
	local B = ((M - rgb[3]) << 12) / c
	local h
	if M == rgb[1]
		h = B - G
	elseif M == rgb[2]
		h = (2 << 12) + R - B
	elseif M == rgb[3]
		h = (4 << 12) + G - R
	end

	h = (((h / 6) & 0xfff) * 360) >> 12
	return { h, s, M * 100 / 15 }
end

local colormap = {
	["%^0"] = "\x8f",
	["%^1"] = "\x85",
	["%^2"] = "\x83",
	["%^3"] = "\x82",
	["%^4"] = "\x84",
	["%^5"] = "\x88",
	["%^6"] = "\x81",
	["%^7"] = "\x80",
	["%^8"] = "\x86",
	["%^9"] = "\x86",
}

local color_format_table = {
	RGBtoHSV({ 15, 7, 15 }),
	RGBtoHSV({ 15, 15, 0 }),
	RGBtoHSV({ 7, 14, 4 }),
	RGBtoHSV({ 7, 7, 15 }),
	RGBtoHSV({ 15, 7, 7 }),
	RGBtoHSV({ 11, 11, 11 }),
	RGBtoHSV({ 15, 9, 3 }),
	RGBtoHSV({ 7, 14, 15 }),
	RGBtoHSV({ 12, 9, 15 }),
	RGBtoHSV({ 6, 14, 12 }),
	RGBtoHSV({ 12, 14, 0 }),
	RGBtoHSV({ 12, 12, 15 }),
	RGBtoHSV({ 14, 9, 6 }),
	RGBtoHSV({ 15, 9, 12 }),
}

local color_escape_table = {
	"^7",
	"^xf7f",
	"^3",
	"^x7e4",
	"^x77f",
	"^xf77",
	"^xbbb",
	"^xf93",
	"^x7ef",
	"^xc9f",
	"^x6ec",
	"^xce0",
	"^xccf",
	"^xe96",
	"^xf9c",
	"^0",
}

local function CubeDistance(x, y)
	local v = { x[1] - y[1], x[2] - y[2], x[3] - y[3] }
	return FixedSqrt((v[1] * v[1] + v[2] + v[2] + v[3] * v[3]) << FRACBITS)
end

COM_AddCommand("__m", function (player, msg)
	local i
	for k, v in pairs(colormap) do
		while true do
			i = msg:find(k, i)
			if i == nil then
				break
			end
			if i == 1 or msg:sub(i-1, i-1) ~= "^" then
				msg = msg:sub(0, i-1) .. v .. msg:sub(i+2)
			end
			i = i + 1
		end
	end
	i = 0
	while true do
		i = msg:find("%^x[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]", i)
		if i == nil then
			break
		end
		if i == 1 or msg:sub(i-1, i-1) ~= "^" then
			local x = { tonumber(msg:sub(i+2, i+2), 16), tonumber(msg:sub(i+3, i+3), 16), tonumber(msg:sub(i+4, i+4), 16) }
			local dist = 0x7fffffff
			local c = 0
			local s = RGBtoHSV(x)
			if s[1] == 0 then
				if s[3] < 50 then
					c = 15
				end
			else
				for i, y in pairs(color_format_table) do
					local m = min(s[1], y[1])
					local M = max(s[1], y[1])
					local d = (M - m)
					if d > 180 then
						d = 360 - d
					end
					if d < dist
						dist = d
						c = i
					end
				end
			end
			msg = msg:sub(0, i-1) .. string.char(c + 0x80) .. msg:sub(i+5)
		end
		i = i + 1
	end
	msg = msg:gsub("%^%^", "%^")
	chatprint(msg, true)
end, COM_ADMIN)

if isserver then
	local newplayers = {}
	addHook("PlayerJoin", function (playernum)
		table.insert(newplayers, playernum)
	end)

	addHook("ThinkFrame", function ()
		if #newplayers then
			for _, playernum in ipairs(newplayers) do
				-- this logic is delayed, so we have to do it later
				print("^xf80*" .. players[playernum].name .. " has joined the game (player " .. playernum .. ")")
			end
			newplayers = {}
		end
	end)

	addHook("PlayerQuit", function (player, reason)
		if reason == KR_KICK then
			print("^xf80*" .. player.name .. " has been kicked")
		elseif reason == KR_PINGLIMIT then
			print("^xf80*" .. player.name .. " left the game (Broke ping limit)")
		elseif reason == KR_SYNCH then
			print("^xf80*" .. player.name .. " left the game (Synch failure)")
		elseif reason == KR_TIMEOUT then
			print("^xf80*" .. player.name .. " left the game (Connection timeout)")
		elseif reason == KR_BAN then
			print("^xf80*" .. player.name .. " has been banned")
		elseif reason == KR_LEAVE then
			print("^xf80*" .. player.name .. " left the game")
		else
			print("^xf80*" .. player.name .. " somehow disappeared")
		end
	end)

	addHook("PlayerMsg", function (source, type, target, msg)
		if not isdedicatedserver then
			-- clients should ignore this
			return false
		end
		if type ~= 0 then
			-- ignore non-public chat
			return false
		end

		msg = msg:gsub("%^", "%^%^")
		local color = color_escape_table[((skincolors[source.skincolor].chatcolor >> 12) & 0xf) + 1]
		if source.spectator then
			color = "^xbbb"
		end
		local prefix = ""
		if #source == #server then
			prefix = "~"
		elseif IsPlayerAdmin(source) then
			prefix = "@"
		end
		if msg:find("^/me ") then
			print("^7* ^3" .. prefix .. color .. source.name .. " ^7" .. msg:sub(5))
		else
			print(color .. "<^3" .. prefix .. color .. source.name .. "> ^7" .. msg)
		end
		return true
	end)
end
