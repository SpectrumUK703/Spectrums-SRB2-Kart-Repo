local kodapulse = CV_RegisterVar({
	name = "kodapulse",
	defaultvalue = "Off",
	flags = 0,
	possiblevalue = CV_OnOff
})

local kodatable = {}
local HYPRtable = {}

addHook("PreThinkFrame", function(mapnum)
	if not (FS_SHADOW and kodapulse.value) then return end --Is Fuckpak even added?
	if leveltime then return end
	if not kodatable[1]
		for i=0, 31
			if i < 10
				table.insert(kodatable, R_TextureNumForName("~00"..tostring(i)))
				table.insert(HYPRtable, R_TextureNumForName("HYPR0"..tostring(i)))
			else
				table.insert(kodatable, R_TextureNumForName("~0"..tostring(i)))
				table.insert(HYPRtable, R_TextureNumForName("HYPR"..tostring(i)))
			end
		end
	end
	for sec in sectors.iterate do
		local floorpic = sec.floorpic
		local ceilingpic = sec.ceilingpic
		if floorpic:sub(1,2) == "~0"
			local numberstring = floorpic:sub(3,4)
			local number = tonumber(numberstring)
			if number ~= nil and number >= 0 and number <= 31
				sec.floorpic = "HYPS"..numberstring
			end
		end
		if ceilingpic:sub(1,2) == "~0"
			local numberstring = ceilingpic:sub(3,4)
			local number = tonumber(numberstring)
			if number ~= nil and number >= 0 and number <= 31
				sec.ceilingpic = "HYPS"..numberstring
			end
		end
	end
	for side in sides.iterate do
		local toptexture = side.toptexture
		local midtexture = side.midtexture
		local bottomtexture = side.bottomtexture
		for k,v in ipairs(kodatable)
			if toptexture == v
				side.toptexture = HYPRtable[k]
			end
			if midtexture == v
				side.midtexture = HYPRtable[k]
			end
			if bottomtexture == v
				side.bottomtexture = HYPRtable[k]
			end
		end
	end
end)