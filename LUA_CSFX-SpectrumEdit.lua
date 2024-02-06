// Lighto's copy slope fix, edit by haya
// Feel free to steal and mangle
-- Ripped out of Deltatracks and edited by Spectrum to improve performance

if (copyslopefix_initialized) then return end // Check if it's already been loaded.

local FF_EXISTS = FF_EXISTS
local FF_SOLID = FF_SOLID
local FF_QUICKSAND = FF_QUICKSAND
local FF_SWIMMABLE = FF_SWIMMABLE
local MF2_OBJECTFLIP  = MF2_OBJECTFLIP
local FRACUNIT = FRACUNIT
local MF_NOTHINK = MF_NOTHINK
local MF_NOBLOCKMAP = MF_NOBLOCKMAP
local MT_BOSS3WAYPOINT = MT_BOSS3WAYPOINT

local function P_GetSlopeZAt(slope,  x,  y)
	local dist = FixedMul(x - slope.o.x, slope.d.x) +
	               FixedMul(y - slope.o.y, slope.d.y)
	return slope.o.z + FixedMul(dist, slope.zdelta)
end

local function L_GetSectorCeilingZAt(sector, x, y)
	if sector.c_slope then
		return P_GetSlopeZAt(sector.c_slope, x, y)
	end
	return sector.ceilingheight
end

local function L_GetFFloorTopZAt(ffloor, x, y)
	if ffloor.t_slope then
		return P_GetSlopeZAt(ffloor.t_slope, x, y)
	end
	return ffloor.topheight
end

local function L_GetFFloorBottomZAt(ffloor, x, y)
	if ffloor.b_slope then
		return P_GetSlopeZAt(ffloor.b_slope, x, y)
	end
	return ffloor.bottomheight
end

local function L_CeilingzAtPos(x, y, z, height)
	local sec = R_PointInSubsector(x, y).sector
	local ceilingz = L_GetSectorCeilingZAt(sec, x, y)
	for rover in sec.ffloors() do
		if not (rover and rover.valid) then continue end
		if not (rover.flags & FF_EXISTS) then continue end
		if not (rover.flags & FF_SOLID or rover.flags & FF_QUICKSAND) or (rover.flags & FF_SWIMMABLE) then continue end
		
		local delta1, delta2, thingtop = z + height, z + height, z + height
		local topheight, bottomheight
		
		topheight    = L_GetFFloorTopZAt   (rover, x, y)
		bottomheight = L_GetFFloorBottomZAt(rover, x, y)

		if (rover.flags & FF_QUICKSAND) then
			if (thingtop > bottomheight and topheight > z) then
				if (ceilingz > z) then
					ceilingz = z
				end
			end
			continue
		end

		delta1 = z - (bottomheight + ((topheight - bottomheight)/2))
		delta2 = thingtop - (bottomheight + ((topheight - bottomheight)/2))
		if (bottomheight < ceilingz and abs(delta1) > abs(delta2)) then
			ceilingz = bottomheight
		end
	end

	return ceilingz
end

local ATS_MAPTHING = 1
local ATS_MAPOBJECT = 2

// creates a thok'd clone of a scenery mapthing
local function L_CreateThokClone(mt, skip)
	if not (mt.mobj and mt.mobj.valid) then return end
	if mt.mobj.type == MT_BOSS3WAYPOINT then return end // please dont
	if not (mt.mobj.flags & MF_NOTHINK) then return end
	
	if skip then P_RemoveMobj(mt.mobj) return end
	
	local mo = mt.mobj
	
	local thok = P_SpawnMobj(mo.x, mo.y, mo.z, MT_THOK)
	thok.flags = mo.flags & ~(MF_NOTHINK|MF_NOBLOCKMAP)
	K_MatchGenericExtraFlags(thok, mo)
	thok.state = mo.state
	thok.frame = mo.frame
	thok.sprite = mo.sprite
	
	thok.radius = mo.radius
	thok.height = mo.height
	
	P_RemoveMobj(mt.mobj)
end

// Remove the thing's spawned mobj prematurely.
-- addHook("PlayerJoin", function(net)
-- 	if not mapheaderinfo[gamemap].copyslopefix then return end
-- 	for thing in mapthings.iterate do
-- 		if not (thing and thing.valid) then continue end
-- 		// L_CreateThokClone(thing, true)
-- 	end
-- end)

local function L_AdjustToSlope(type, moth)
	local fh, ch = 0, 0 // floor height, ceiling height
	if type == ATS_MAPOBJECT then // mobj
		local sec = R_PointInSubsector(moth.x, moth.y).sector
		local zh = 0 // spawnpoint height
		if moth.spawnpoint then
			zh = (moth.spawnpoint.options<<12)
		end
		ch = L_CeilingzAtPos(moth.x, moth.y, moth.z, moth.height)
		fh = P_FloorzAtPos(moth.x, moth.y, moth.z, moth.height)
		
		if moth.flags2 & MF2_OBJECTFLIP then
			if not sec.c_slope then return end
			moth.z = ch - moth.height - zh
		else
			if not sec.f_slope then return end
			moth.z = fh + zh
		end
	elseif type == ATS_MAPTHING then // thing
		// this adjust mapthings so objects that respawn, respawn in the correct position
		local sec = R_PointInSubsector(moth.x*FRACUNIT, moth.y*FRACUNIT).sector
		local zh = moth.options>>4 // thing z height
		local height = 16*FRACUNIT
		if moth.mobj then
			height = moth.mobj.height
		end
		ch = L_CeilingzAtPos(moth.x*FRACUNIT, moth.y*FRACUNIT, moth.z*FRACUNIT, height)
		fh = P_FloorzAtPos(moth.x*FRACUNIT, moth.y*FRACUNIT, moth.z*FRACUNIT, height)
		if moth.options & 2 then // flip
			if not sec.c_slope then return end
			moth.z = ch - zh - height
		else
			if not sec.f_slope then return end
			moth.z = fh + moth.z
		end
-- 		if (sec.c_slope or sec.f_slope) then
-- 			// L_CreateThokClone(moth, false)
-- 		end
	end
end

local runscript = false
addHook("MapLoad", do
	runscript = (mapheaderinfo[gamemap].copyslopefix ~= nil)
end)
addHook("NetVars", function(net) runscript = net($) end) // might as well be paranoid
addHook("ThinkFrame", do
	if leveltime ~= 2 then return end // oh we doing this again, huh?
	if runscript then
		for mo in mobjs.iterate() do
			if not (mo and mo.valid) then continue end
			L_AdjustToSlope(ATS_MAPOBJECT, mo)
		end
		// MapThingSpawn where are you
		for thing in mapthings.iterate do
			if not (thing and thing.valid) then continue end
			L_AdjustToSlope(ATS_MAPTHING, thing)
		end
		runscript = false // only run once
	end
end)

rawset(_G, "copyslopefix_initialized", true)