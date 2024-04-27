local maptextures = {}
local mapmidtextures = {}
local mapflats = {}
local soundtextures = {}
local debris = {}
local k_position = k_position
local srb2kart = (k_position ~= nil) //I think this should work for any of the Kart global constants

local setting = CV_RegisterVar({
	name = "texturerandomizer",
	defaultvalue = "within_level",
	flags = CV_NETVAR,
	PossibleValue = {off=0,within_level=1,between_levels=2},
})

local kodarandomize = CV_RegisterVar({
	name = "randomizekodachrome",
	defaultvalue = "Off",
	flags = CV_NETVAR|CV_CALL,
	PossibleValue = CV_OnOff,
	func = function(arg)
		if arg.value
			print("\x82WARNING: \x80This will make Kodachrome Void worse for players with photosensitivity issues.")
		end
	end,
})

local function IsThisStored(flat, table)
	if #table == 0 then
		return false
	end
	for i,v in ipairs(table)
		if v == flat
			return true
		end
	end
	return false
end

local function DoTablesMatch(table, table2)
	if #table ~= #table2
		return false
	end
	for i,v in ipairs(table)
		if v ~= table2[i]
			return false
		end
	end
	return true
end

local function IsTableStored(table, table2)
	if #table2 == 0 then
		return false
	end
	for i,v in ipairs(table2)
		if DoTablesMatch(table, v)
			return true
		end
	end
	return false
end

local function RemoveSomeEntries(tbl)
	for i,v in ipairs(tbl)
		if P_RandomChance((i+#tbl)*FRACUNIT/(4*#tbl)) then
			table.remove(tbl, i)
		end
	end
	--print("some textures removed")
end

local function randomizetextures()
	if setting.value ~= 2
		maptextures = {}
		mapmidtextures = {}
		mapflats = {}
		soundtextures = {}
		debris = {}
		--print("texture tables cleared")
	end
	if not setting.value then return end
	if not kodarandomize.value and ((not srb2kart and gamemap == 491) //Kodachrome Void in SRB2
	or (srb2kart and (gamemap == 36 or gamemap == 383))) then return end //Kodachrome Void in Kart (and the one I moved to MAPHV in my frozen edit)
	for sec in sectors.iterate do
		if sec.floorpic ~= "F_SKY1" and sec.floorpic ~= "PIT"
		and ((not srb2kart) or (not string.find(sec.floorpic, "BOST") //Kart boost pads
		and not string.find(sec.floorpic, "ARROW") //Kart boost pads
		and not string.find(sec.floorpic, "SPRIN"))) //Kart spring pads
		and ((not srb2p) or string.sub(sec.floorpic,1,4) ~= "GATE") //SRB2P gates
		and (IsThisStored(sec.floorpic, mapflats) == false) then
			table.insert(mapflats, sec.floorpic)
		end
		if sec.ceilingpic ~= "F_SKY1" and sec.ceilingpic ~= "PIT" 
		and ((not srb2kart) or (not string.find(sec.ceilingpic, "BOST") //Kart boost pads
		and not string.find(sec.ceilingpic, "ARROW") //Kart boost pads
		and not string.find(sec.ceilingpic, "SPRIN"))) //Kart spring pads
		and ((not srb2p) or string.sub(sec.ceilingpic,1,4) == "GATE")
		and (IsThisStored(sec.ceilingpic, mapflats) == false) then
			table.insert(mapflats, sec.ceilingpic)
		end
	end
	for side in sides.iterate do
		if side.special == 414 then
			if side.toptexture and (IsThisStored(side.toptexture, soundtextures) == false) then
				table.insert(soundtextures, side.toptexture)
			end
			if side.midtexture and (IsThisStored(side.midtexture, soundtextures) == false) then
				table.insert(soundtextures, side.midtexture)
			end
		elseif side.special == 14 and side.toptexture then
			local sidetable = {}
			table.insert(sidetable, 1, side.toptexture)
			table.insert(sidetable, 2, side.midtexture)
			table.insert(sidetable, 3, side.bottomtexture)
			if (IsTableStored(sidetable, debris) == false) then
				table.insert(debris, sidetable)
			end
			sidetable = {}
		elseif side.special ~= 9 and side.special ~= 442 and side.special ~= 405 and side.special ~= 461 and side.special ~= 606 then
			if side.toptexture and side.toptexture > 0 
			and ((not srb2p) or (side.toptexture ~= R_TextureNumForName("GATER")
			and side.toptexture ~= R_TextureNumForName("GATEB")
			and side.toptexture ~= R_TextureNumForName("GATEY")))
			and (IsThisStored(side.toptexture, maptextures) == false) then
				table.insert(maptextures, side.toptexture)
			end
			if side.bottomtexture and side.bottomtexture > 0 
			and ((not srb2p) or (side.bottomtexture ~= R_TextureNumForName("GATER")
			and side.bottomtexture ~= R_TextureNumForName("GATEB")
			and side.bottomtexture ~= R_TextureNumForName("GATEY")))
			and (IsThisStored(side.bottomtexture, maptextures) == false) then
				table.insert(maptextures, side.bottomtexture)
			end
			if side.midtexture and side.midtexture > 0 
			and (side.repeatcnt ~= 0 or side.special < 700 or side.special > 799) 
			and (IsThisStored(side.midtexture, mapmidtextures) == false) then
				table.insert(mapmidtextures, side.midtexture)
			end
		end
	end
	for sec in sectors.iterate do
		if sec.floorpic ~= "F_SKY1" and sec.floorpic ~= "PIT" 
		and ((not srb2kart) or (not string.find(sec.floorpic, "BOST") //Kart boost pads
		and not string.find(sec.floorpic, "ARROW") //Kart boost pads
		and not string.find(sec.floorpic, "SPRIN"))) //Kart spring pads
		and ((not srb2p) or string.sub(sec.floorpic,1,4) ~= "GATE") then
			sec.floorpic = mapflats[P_RandomRange(1, #mapflats)]
		end
		if sec.ceilingpic ~= "F_SKY1" and sec.ceilingpic ~= "PIT" 
		and ((not srb2kart) or (not string.find(sec.ceilingpic, "BOST") //Kart boost pads
		and not string.find(sec.ceilingpic, "ARROW") //Kart boost pads
		and not string.find(sec.ceilingpic, "SPRIN"))) //Kart spring pads
		and ((not srb2p) or string.sub(sec.ceilingpic,1,4) ~= "GATE") then
			sec.ceilingpic = mapflats[P_RandomRange(1, #mapflats)]
		end
	end
	for side in sides.iterate do
		if side.special == 414 then
			if side.toptexture then
				side.toptexture = soundtextures[P_RandomRange(1, #soundtextures)]
			end
			if side.midtexture then
				side.midtexture = soundtextures[P_RandomRange(1, #soundtextures)]
			end
		elseif side.special == 14 then
			local tablenumber = P_RandomRange(1, #debris)
			side.toptexture = debris[tablenumber][1]
			side.midtexture = debris[tablenumber][2]
			side.bottomtexture = debris[tablenumber][3]
			tablenumber = nil
		elseif side.special ~= 9 and side.special ~= 442 and side.special ~= 405 and side.special ~= 461 then
			if side.toptexture
			and ((not srb2p) or (side.toptexture ~= R_TextureNumForName("GATER")
			and side.toptexture ~= R_TextureNumForName("GATEB")
			and side.toptexture ~= R_TextureNumForName("GATEY"))) then
				side.toptexture = maptextures[P_RandomRange(1, #maptextures)]
			end
			if side.bottomtexture 
			and ((not srb2p) or (side.bottomtexture ~= R_TextureNumForName("GATER")
			and side.bottomtexture ~= R_TextureNumForName("GATEB")
			and side.bottomtexture ~= R_TextureNumForName("GATEY"))) then
				side.bottomtexture = maptextures[P_RandomRange(1, #maptextures)]
			end
			if side.midtexture and side.repeatcnt ~= 0 then
				side.midtexture = mapmidtextures[P_RandomRange(1, #mapmidtextures)]
			end
		end
	end
	--print("maptextures: " .. tostring(#maptextures), "mapmidtextures: " .. tostring(#mapmidtextures), "mapflats: " .. tostring(#mapflats), "soundtextures: " .. tostring(#soundtextures), "debris: " .. tostring(#debris))
	if setting.value ~= 2
		maptextures = {}
		mapmidtextures = {}
		mapflats = {}
		soundtextures = {}
		debris = {}
		--print("texture tables cleared")
	end
end

addHook("MapLoad", randomizetextures)

addHook("ThinkFrame", do
	while #mapflats >= 128
		RemoveSomeEntries(mapflats)
	end
	while #maptextures >= 128
		RemoveSomeEntries(maptextures)
	end
	while #mapmidtextures >= 128
		RemoveSomeEntries(mapmidtextures)
	end
	while #soundtextures >= 32
		RemoveSomeEntries(soundtextures)
	end
	while #debris >= 32
		RemoveSomeEntries(debris)
	end
	if srb2p //Run the randomizer between dungeon floors too
	and server and server.entrytime == TICRATE
		randomizetextures()
	end
end)

addHook("NetVars", function(net)
	maptextures=net($)
	mapmidtextures=net($)
	mapflats=net($)
	soundtextures=net($)
	debris=net($)
end)