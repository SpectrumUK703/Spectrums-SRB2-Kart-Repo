local g = rawset
local v

for i=1, #spr2defaults
	v = spr2names[i-1]
	if dprint
		dprint("Globalize... SPR2_"..v.."->"..i-1)
	end
	g(_G, "SPR2_"..v, i-1)
end

local function table_pack(...)
    return {n=select("#", ...), ...}
end

local fs = freeslot
rawset(_G, "freeslot", function(...)

	local args = {...}

	-- call original freeslot function
	-- nah, not yet
	--local ints = table_pack(fs(unpack(args)))
	local ints = {}

	-- globalize the results.
	for i = 1, #args do

		-- spr2 does some weird things here so let's leave it out for now.
		--Either I've fixed whatever that was, or I haven't noticed it yet.
		/*if string.upper(args[i]:sub(1, 5)) == "SPR2_"
			continue
		end*/

		if string.upper(args[i]:sub(1, 4)) == "SFX_"
			args[i] = string.lower(args[i])
		else
			args[i] = string.upper(args[i])
		end

		--If you freeslot the same thing twice, the second freeslot returns the wrong value
		table.insert(ints, rawget(_G, args[i]) or fs(args[i]))
		
		if dprint
			dprint("Globalize... "..tostring(args[i]).."->"..tostring(_G[args[i]]))
		end

		g(_G, args[i], _G[args[i]])
	end
	
	return unpack(ints)
end)