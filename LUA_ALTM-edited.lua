--AAAAAAAAAAAAAAAAAAAA

--AlterMap v1.0 by Chaobrother. This is a script remodeled from Paradise Illusion.
--Toggles the normal look of a stage to something else.
-- Parameters
-- 0: Normal Standard, Encore Alternate
-- 1: Normal Alternate, Encore Standard
-- 2: Normal and Encore Standard mode. This is the default.
-- 3: Normal and Encore Alternate mode.
-- Level Header parameters:
--[[
	lua.altermap: This level has an alternate mode where the default can be changed
					with a console command. Make sure to call ALTERMAPDECLARATION
					with your map number in an external script for proper operation.
	lua.altermapsky: Sets the sky to the number defined when loaded into alternate mode.
	lua.altermapexecute: A linedef number to execute when in alternate mode.  
	lua.altermapbrightness: Increments all sector brightnesses by the number defined. 
	lua.altermapflats: A comma seperated list of flats to replace. The pattern is
						oldflat, newflat. If there are too many caracters to fit 
						in one argument use altermapflats1 to altermapflats[n] instead,
						where [n] is any number (without brackets).
	lua.altermaptextures: Same usage as altermapflats but for textures.
	lua.altermapencore: Enables an Encore mode hack which will force the map to load in its
	Encore style without the palette at the expense of the map not flipping. This will only
	occur if the unused style is shown in Encore with altermap command parameters 0 or 1.
]]
--Linedef executor ALTERMAP does alternate mode operations without needing a console
--variable or being an altermap.

local commtable = commtable or {}

-- Call this function in a different script to setup an altermap.
-- i is map index, command is a custom command which can be 
-- used to change value and be called for other checks outside of this script.
-- value is the default altermap argument for your map.
-- You may need to change or add a command to your map if there is a netid conflict.
local ALTERMAPDECLARATION_local = function(i,command,value)
	if not commtable[i]
		if command ~= nil
			commtable[i] = CV_RegisterVar({
				name = command,
				defaultvalue = value or "Off",
				flags = CV_NETVAR,
				possiblevalue = {Off = 0, On = 1, Never = 2, Always = 3}
			})
			rawset(_G,command,commtable[i])
		else
			commtable[i] = CV_RegisterVar({
				name = "alter"..string.lower(G_BuildMapName(i)),
				defaultvalue = value or "Off",
				flags = CV_NETVAR,
				possiblevalue = {Off = 0, On = 1, Never = 2, Always = 3}
			})
		end
	end
end
rawset(_G, "ALTERMAPDECLARATION", ALTERMAPDECLARATION_local)

ALTERMAPDECLARATION(421, "snowydesert", "Off")
ALTERMAPDECLARATION(1020,"paradiseillusion", "Never")

if AlternateMapLib return end
rawset(_G,"AlternateMapLib",true)
rawset(_G, "ISALTERMODE", false)

local function tableparse(x)
	if not x return {} end
	local y = {}
	local i = 0
	for word in x:gmatch('[^,%s]+') do
		y[i+1] = word 
		i = $+1
	end	
	return y
end

-- garbage string for swapping, B311RGIM
--[[Converts a level header with texture swaps (A->B) (B->A)
	to a list which facilitates practically doing so (A->C)(B->A)(C->B)
	currently non-functional due to some unknowns and combos of swaps/nonswaps]]
local function swapparse(x)
	local haveSeen = {}
	local swapindex = {}
	for i = 1, #x do
		local element = x[i]
		if not haveSeen[element] then	
			haveSeen[element] = {i}
		else
			table.insert(haveSeen[element],i)
		end
	end
	for k,v in pairs(haveSeen)
		print(#v)
	end
	
	for i=1, #x do
		--0,1,1,0
		--1,2,0,1,2,0
		if #haveSeen[x[i]] == 1 --unique value
			table.insert(swapindex,x[i])
		else
			for j = 1, #haveSeen[x[i]]
				if haveSeen[x[i]][j] % 2 ~= 0 and i > haveSeen[x[i]][j] --from value
					table.insert(swapindex,x[i+1])
					table.insert(swapindex,"GFZROCK")
					table.insert(swapindex,x[i])
					table.insert(swapindex,x[i+1])
					table.insert(swapindex,"GFZROCK")
					table.insert(swapindex,x[i])
					--haveSeen[x[i]][j] = i 
				end
				break
			end
		end
	end
	
	for i = 1 , #swapindex do
		if swapindex[i]
	    	--print(swapindex[i].." ")
		end
	end
	return swapindex
end

local function tableconcat(param)
	local i = 1
	local z = tableparse(mapheaderinfo[gamemap][param])
	local y = {}
	repeat
		y = tableparse(mapheaderinfo[gamemap][param..i])
		if not y break end
		for j = 1 , #y
			table.insert(z,y[j])
		end
		i = $1 + 1
	until not mapheaderinfo[gamemap][param..i]
	return z
end

--Function which handles all altermapalterations
--[[Linedef Properties
	-Backside texture: Name is appended to altermapflats and altermaptextures
	for the potential of multiple textureswaps.
	-Front side X offset determines global brightnees increment.
	-Block Enemies will make the linedef only affect global brightness.
	]]
local function doaltermap(j,mo,d)
	local flatset = {}
	local textureset = {}
	local brightmod = 0
	
	if not j
		if mapheaderinfo[gamemap].altermapsky
			P_SetupLevelSky(tonumber(mapheaderinfo[gamemap].altermapsky), true)
		end
		if mapheaderinfo[gamemap].altermapexecute
			P_LinedefExecute(tonumber(mapheaderinfo[gamemap].altermapexecute))
		end
	end
	if not j or ~(j.flags & ML_BLOCKMONSTERS)
		if j and j.backside
			if mapheaderinfo[gamemap]["altermapflats"..string.lower(j.backside.text)]
				flatset = tableconcat("altermapflats"..string.lower(j.backside.text))
			end
			if mapheaderinfo[gamemap]["altermaptextures"..string.lower(j.backside.text,"ALTERMAP")]
				textureset = tableconcat("altermaptextures"..string.lower(j.backside.text,"ALTERMAP"))
			end
		else
			if mapheaderinfo[gamemap].altermapflats
				flatset = tableconcat("altermapflats")
			end
			if mapheaderinfo[gamemap].altermaptextures
				textureset = tableconcat("altermaptextures")
			end
		end
	end
	
	if j
		brightmod = j.frontside.textureoffset/FRACUNIT
	elseif mapheaderinfo[gamemap].altermapbrightness
		brightmod = tonumber(mapheaderinfo[gamemap].altermapbrightness)
	end
	
	--Texture Replacement
	for s in sectors.iterate
		s.lightlevel = $1 + brightmod
		for i = 1 , #flatset, 2
			if s.floorpic == flatset[i]
				s.floorpic = flatset[i+1]
			end
			if s.ceilingpic == flatset[i]
				s.ceilingpic = flatset[i+1]
			end
		end
	end
	
	local function textureswap(l,old,swap)
		if (l.special == 439)
				return
		end

		--Front side
		local this = l.frontside
		if (this.toptexture == old) this.toptexture = swap end
		if (this.midtexture == old ) this.midtexture = swap end
		if (this.bottomtexture == old) this.bottomtexture = swap end

		if l.backside == nil
			return --One-sided stops here.
		end

		--Back side
		local this = l.backside;
		if (this.toptexture == old) this.toptexture = swap end
		if (this.midtexture == old) this.midtexture = swap end
		if (this.bottomtexture == old ) this.bottomtexture = swap end
	end
	
	for l in lines.iterate
		for i = 1 , #textureset, 2
		textureswap(l,R_TextureNumForName(textureset[i]),R_TextureNumForName(textureset[i+1]))
		end
	end
end
addHook("LinedefExecute", doaltermap,"ALTERMAP")

addHook("MapChange",function()
	if not mapheaderinfo[gamemap].altermap == true
		return
	end
	if not commtable[gamemap]
		rawset(_G, "ALTERMAPDECLARATION", ALTERMAPDECLARATION_local)
		ALTERMAPDECLARATION_local(gamemap)
	end
end)

addHook("MapLoad", function(mapnum)
	if not mapheaderinfo[gamemap].altermap == true
		return
	end
	if (commtable[gamemap].value == 1 and encoremode == true) or (commtable[gamemap].value == 0 and encoremode == false)
		or (commtable[gamemap].value == 2)
		ISALTERMODE = false 
		--See what you are missing in Encore mode.
		return
	end
	ISALTERMODE = true
	doaltermap()
end)

local oldaltvar
local function altmodevars(net)
	oldaltvar = net($)
end

addHook("ThinkFrame",function() --Hacky method to supress encore when altermap is on or off.
	if not mapheaderinfo[gamemap].altermap or not (commtable[gamemap].value == 1 or commtable[gamemap].value == 0)
		or(encoremode == false)
		return 
	end
	--Using flashpals in encore did not work as intended; the palette would always be a
	--default one (%75 tinted white)
	--[[for p in players.iterate
		P_FlashPal(p,7,1)
	end]]
	
	--Reload the map instead
	if mapheaderinfo[gamemap].altermapencore
		if leveltime == 1
			oldaltvar = commtable[gamemap].value
			local changeval
			if commtable[gamemap].value == 1
				changeval = 2
			end
			if commtable[gamemap].value == 0
				changeval = 3
			end
			COM_BufInsertText(server, commtable[gamemap].name.." "..changeval)
			if CV_FindVar("kartencore").value == 1
				COM_BufInsertText(server, "map "..gamemap.." -e")
			else 
				COM_BufInsertText(server, "kartencore off")
				COM_BufInsertText(server, "map "..gamemap)
			end 
			COM_BufInsertText(server, "wait 1")
			COM_BufInsertText(server, commtable[gamemap].name.." "..oldaltvar)
		end
	end
end)

