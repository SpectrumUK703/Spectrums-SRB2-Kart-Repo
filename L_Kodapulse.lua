local kodapulse = CV_RegisterVar({
	name = "kodapulse",
	defaultvalue = "Off",
	possiblevalue = CV_OnOff
})

local kodatable = {}
local HYPRtable = {}
local floortable = {}
local ceilingtable = {}
local pairs = pairs
local tostring = tostring
local R_TextureNumForName = R_TextureNumForName
local insert = insert
local sub = sub
local iterate = iterate
local table = table
local floorpic = floorpic
local ceilingpic = ceilingpic
local toptexture = toptexture
local midtexture = midtexture
local bottomtexture = bottomtexture

addHook("ThinkFrame", do
	local time = leveltime
	if not (time%4)
		local quartertime = time/4
		for k,v in pairs(floortable)
			local sec = v[1]
			local number = v[2]
			sec.floorpic = "KODAP"..tostring(((213+number*3+(quartertime))%426)+1)
		end
		for k,v in pairs(ceilingtable)
			local sec = v[1]
			local number = v[2]
			sec.ceilingpic = "KODAP"..tostring(((213+number*3+(quartertime))%426)+1)
		end
	end
end)

addHook("MapChange", function(mapnum)
	floortable = {}
	ceilingtable = {}
end)

addHook("MapLoad", function(mapnum)
	floortable = {}
	ceilingtable = {}
	if not (FS_SHADOW and kodapulse.value) then return end --Is Fuckpak even added?
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
		local secfloorpic = sec.floorpic
		local secceilingpic = sec.ceilingpic
		if secfloorpic:sub(1,2) == "~0"
			local numberstring = secfloorpic:sub(3,4)
			local number = tonumber(numberstring)
			if number ~= nil and number >= 0 and number <= 31
				sec.floorpic = "HYPS"..numberstring
				local sectable = {sec, number}
				table.insert(floortable, sectable)
			end
		end
		if secceilingpic:sub(1,2) == "~0"
			local numberstring = secceilingpic:sub(3,4)
			local number = tonumber(numberstring)
			if number ~= nil and number >= 0 and number <= 31
				sec.ceilingpic = "HYPS"..numberstring
				local sectable = {sec, number}
				table.insert(ceilingtable, sectable)
			end
		end
	end
	for side in sides.iterate do
		local sidetoptexture = side.toptexture
		local sidemidtexture = side.midtexture
		local sidebottomtexture = side.bottomtexture
		for k,v in pairs(kodatable)
			if sidetoptexture == v
				side.toptexture = HYPRtable[k]
			end
			if sidemidtexture == v
				side.midtexture = HYPRtable[k]
			end
			if sidebottomtexture == v
				side.bottomtexture = HYPRtable[k]
			end
		end
	end
end)