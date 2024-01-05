rawset(_G, "wp_orbi" , CV_RegisterVar({
	name = "wp_orbi",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}))

rawset(_G, "wp_jawz" , CV_RegisterVar({
	name = "wp_jawz",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}))

local FRACUNIT = FRACUNIT
local TICRATE = TICRATE
local speedcap = 75

local function Clamp(value, newmin ,newmax)
	return min(newmax,max(newmin,value))
end

local function Rescale(value, oldmin, oldmax, newmin, newmax)
	value = Clamp(value, oldmin, oldmax)
	return newmin +  FixedMul(FixedDiv( value-oldmin , oldmax-oldmin), newmax-newmin)
end

local function RandomFixedRange(a, b)
	return FixedMul(P_RandomFixed(), b-a)+a
end

local function MobjScale(fracunits)
	return FixedMul(fracunits, mapobjectscale)
end

-- returns true or false, instead of -1 or 1
local function MobjFlipped(mo)
	return P_MobjFlip(mo) < 0
end

local scrollingTags = {}
local function ScrollingSector(mo)
	if P_IsObjectOnGround(mo)
		local tag = mo.subsector.sector.tag
		if scrollingTags[tag] then
			local line = scrollingTags[tag]
			
			if not (line and line.valid) then 
				print("Item: line_t with tag "..tag.." on map "..(mapheaderinfo[gamemap].lvlttl).." is null for local player "..(consoleplayer or "").." please send replay and log.txt to Ashnal")
				return {0, 0}
			end
			
			return {FixedMul(line.dx, 1*FRACUNIT/8), FixedMul(line.dy, 1*FRACUNIT/8)}
		end
	end
	return {0, 0}
end

local isThereFloorScrollerLinedefs = false
local LINEDEF_FLOOR_SCROLLER = 530
local LINEDEF_CEILING_SCROLLER = 533
local SCROLL_SHIFT = 5

local function buildTagLinedefTable()
	scrollingTags = {}
	for line in lines.iterate do
		if line.valid and (line.special == LINEDEF_FLOOR_SCROLLER or line.special == LINEDEF_CEILING_SCROLLER) then
			scrollingTags[line.tag] = line
			isThereFloorScrollerLinedefs = true
		end
	end
end
addHook("MapLoad", buildTagLinedefTable)
addHook("NetVars", buildTagLinedefTable)

local MF_NOCLIPHEIGHT = MF_NOCLIPHEIGHT
local function InSectorSpecial(mo, grounded, section, special)
	local fofsector = P_ThingOnSpecial3DFloor(mo)
	-- You can be inside a FoF without being grounded
	if fofsector then
		--print("fofsector "..(fofsector and "yes" or "no"))
		if GetSecSpecial(fofsector.special,section) == special then
			--print("has special "..section.." "..special)
			return fofsector
		end
	end
	if GetSecSpecial(mo.subsector.sector.special, section) == special then
		if not grounded then
			return mo.subsector.sector
		elseif grounded and P_IsObjectOnGround(mo) then
			local flipped = MobjFlipped(mo)
			local slope = flipped and mo.subsector.sector.c_slope or mo.subsector.sector.f_slope -- no FoF
			local savedz = mo.z
			mo.z = mo.z -- update flooz/ceilingz, since they won't match properly for this tic yet
			local savedplanez = flipped and mo.ceilingz or mo.floorz -- current position floorz/ceilingz
			mo.flags = $|MF_NOCLIPHEIGHT -- we need to noclip it to make sure a bordering sector/fof doesnt mess with the floorz/ceilingz checking
			mo.z = slope and P_GetZAt(slope, mo.x, mo.y) or flipped and mo.subsector.sector.ceilingheight or mo.subsector.sector.floorheight -- sets floorz and ceilingz using hardcode functions we can't access from here
			local notonfof = savedplanez == (flipped and mo.ceilingz or mo.floorz) -- if our actual z is the same as the calculated floorz/ceilingz for this sector's slope, we aren't on a FoF
			mo.flags = $ & ~MF_NOCLIPHEIGHT
			mo.z = savedz
			return notonfof and mo.subsector.sector or nil
		end
	end
	return nil
end

local MT_FASTLINE = MT_FASTLINE
local fast
local function SpawnFastLines(mo, scale, color)
	fast = P_SpawnMobj(mo.x + (P_RandomRange(-60,60) * mo.scale),
					   mo.y + (P_RandomRange(-60,60) * mo.scale),
					   mo.z + (mo.height/2) + (P_RandomRange(-20,20) * mo.scale),
					   MT_FASTLINE)
	fast.angle = R_PointToAngle2(0, 0, mo.momx, mo.momy)
	fast.momx = 3*mo.momx/4
	fast.momy = 3*mo.momy/4
	fast.momz = 3*mo.momz/4
	fast.color = color
	fast.colorized = true
	fast.scale = FixedMul(scale,mo.scale)
	K_MatchGenericExtraFlags(fast, mo)
end

local MF_NOCLIPHEIGHT = MF_NOCLIPHEIGHT
local MF_NOGRAVITY = MF_NOGRAVITY
local ORIG_FRICTION = 62914
local thrust
local function P_ButteredSlope(mo)

	if not mo.standingslope then return end
	--if mo.standingslope.flags & SL_NOPHYSICS then 
		-- Actually, do it anyways
	--end
	if mo.flags & (MF_NOCLIPHEIGHT|MF_NOGRAVITY) then return end

	thrust = sin(mo.standingslope.zangle) * 15 / 16 * -(P_MobjFlip(mo))

	if mo.momx or mo.momy then // Slightly increase thrust based on the object's speed
		thrust = FixedMul(thrust, FRACUNIT+FixedHypot(mo.momx, mo.momy)/16)
	end

	// Let's get the gravity strength for the object...
	thrust = FixedMul(thrust, abs(P_GetMobjGravity(mo)))

	// ... and its friction against the ground for good measure (divided by original friction to keep behaviour for normal slopes the same).
	thrust = FixedMul(thrust, FixedDiv(mo.friction, ORIG_FRICTION))

	P_Thrust(mo, mo.standingslope.xydirection, thrust)
end

local function BallSpring(spring, ball)
	local pSpeed = FixedHypot(ball.momx, ball.momy)
	-- Let the original function do the positioning stuff
	P_DoSpring(spring, ball)
	
	local vertispeed = FixedMul(spring.info.mass, FRACUNIT) -- vertical bump to try and match players
	local horizspeed = spring.info.damage

	if vertispeed then
		ball.momz = FixedMul(vertispeed,FixedSqrt(FixedMul(mapobjectscale, spring.scale)))*P_MobjFlip(spring)
	end

	--print("momz after lua spring: "..ball.momz)

	if horizspeed then
		local finalSpeed = FixedDiv(horizspeed, mapobjectscale)
		
		if pSpeed > finalSpeed then
			finalSpeed = pSpeed
		end
		
		P_InstaThrust(ball, spring.angle, FixedMul(finalSpeed,FixedSqrt(FixedMul(mapobjectscale, spring.scale))))
	end
end


local function collideOrbi(mo1, mo2)
	if not (mo1.valid and mo2.valid) then return end
	if not wp_orbi.value then return end
	if (mo2.z > mo1.z + mo1.height) then return false end
	if (mo2.z + mo2.height < mo1.z) then return false end
	
	local item = mo1.itemselfref or mo2.itemselfref
	if not (item and item.valid) then return false end
	
	local notitem = mo1.type ~= MT_ORBINAUT and mo1 or mo2.type ~= MT_ORBINAUT and mo2
	
	if mo1.type == mo2.type then return end
	
	if notitem.flags & MF_SPRING then -- make sure we have spring immunity period after being sprung
		if item.springtimer then return false end
		item.springtimer = 5
		BallSpring(notitem, item)
		return false
	end
end

local function collideJawz(mo1, mo2)
	if not (mo1.valid and mo2.valid) then return end
	if not wp_jawz.value then return end
	if (mo2.z > mo1.z + mo1.height) then return false end
	if (mo2.z + mo2.height < mo1.z) then return false end
	
	local item = mo1.itemselfref or mo2.itemselfref
	if not (item and item.valid) then return false end
	
	local notitem = mo1.type ~= MT_JAWZ and mo1 or mo2.type ~= MT_JAWZ and mo2
	
	if mo1.type == mo2.type then return end
	
	if notitem.flags & MF_SPRING then -- make sure we have spring immunity period after being sprung
		if item.springtimer then return false end
		item.springtimer = 5
		BallSpring(notitem, item)
		return false
	end
end

local items = {MT_ORBINAUT, MT_JAWZ, MT_BALLHOG}
for _,i in ipairs(items) do
	addHook("MobjSpawn", function(mo)
		mo.itemselfref = mo
	end, i)
	
	addHook("MobjThinker", function(mo)
		if not (mo and mo.valid) then return end
		
		if (not wp_orbi.value and mo.type == MT_ORBINAUT) or (not wp_jawz.value and mo.type == MT_JAWZ) then return end
		local velocity = FixedHypot(mo.momx, mo.momy)
		
		local scaledmin = MobjScale(FRACUNIT/3)
		local scaledmax = MobjScale(5<<FRACBITS)
	
		P_ButteredSlope(mo)
		
		mo.friction = Rescale(velocity, scaledmin, scaledmax, ORIG_FRICTION, mo.friction) -- friction recalc after, as it'll make slopes slightly more effective at low speeds
	
		-- Sector specials
		-- sneaker panels
		if InSectorSpecial(mo, true, 4, 6) then
			mo.sneakertimer = 15 -- just for effects and sounds
			if mo.cansneakernoise then
				S_StartSound(mo, sfx_cdfm01)
			end
			mo.cansneakernoise = false
		else
			mo.cansneakernoise = true
		end
		-- spring panels
		if InSectorSpecial(mo, true, 3, 1) or InSectorSpecial(mo, true, 3, 3) then
			local storedballscale = mo.scale
			local storeddestscale = mo.destscale
			--mo.scale = mapobjectscale*5/2
			K_DoPogoSpring(mo, 0, 1)
			mo.scale = storedballscale
			mo.destscale = storeddestscale
		end
	
		-- bouncy floor
		--local fofsector = P_ThingOnSpecial3DFloor(mo)
		--if fofsector and GetSecSpecial(fofsector.special, 1) == 15 then
			--print("hit bouncy fof")
		--end
		-- Too much complicated math and checking that I'd have to reimplement and I dont feel like it
	
		-- zipper
		local zippersector = InSectorSpecial(mo, true, 3, 6) or InSectorSpecial(mo, true, 3, 5)
		if zippersector and not mo.dashpadcooldown then
			--print("found zipper")
			local line = P_FindSpecialLineFromTag(4, zippersector.tag, -1)
			if line ~= -1 then
				local lineangle = R_PointToAngle2(lines[line].v1.x, lines[line].v1.y, lines[line].v2.x, lines[line].v2.y)
				local linespeed = FixedHypot(lines[line].v2.x-lines[line].v1.x, lines[line].v2.y-lines[line].v1.y)
				mo.angle = lineangle
				--print("found controlling line "..lineangle.." "..linespeed)
				if mo.scale/2 > mapobjectscale then
					linespeed = FixedMul(linespeed, mapobjectscale)
				end
				P_InstaThrust(mo, mo.angle, linespeed)
				S_StartSound(mo, sfx_spdpad)
				mo.dashpadcooldown = TICRATE/3
			end
		end		
		mo.dashpadcooldown = max(($ or 0)-1, 0)
	
		if mo.sneakertimer then
			SpawnFastLines(mo, FRACUNIT, SKINCOLOR_WHITE)
			P_Thrust(mo, mo.angle, mapobjectscale*5)
			mo.sneakertimer = $-1
		end
		
	
		-- Recalculate velocity and angles, accounting for after slope physics and considering conveyors for dynamic animation purposes
		local xscrollmod, yscrollmod = unpack(ScrollingSector(mo)) -- will return 0, 0 if not on the ground
		velocity = FixedHypot(mo.momx - xscrollmod, mo.momy - yscrollmod)
		mo.angle = R_PointToAngle2(0, 0, (mo.momx - xscrollmod)*3, (mo.momy - yscrollmod)*3 )
		
		if not P_IsObjectOnGround(mo) then -- mimic the player air speed cap, so that some map jumps work properly
			P_SetObjectMomZ(mo, (3*gravity)/2, true) -- Undoing gravity modifier
			P_InstaThrust(mo, mo.angle, min(speedcap*mapobjectscale, velocity)) -- speedcap
		end
	
		mo.lastslope = mo.standingslope
		mo.lastmomz = mo.momz
		mo.springtimer = max(($ or 0)-1, 0)
	end, i)
	
	if i == MT_ORBINAUT then
		addHook("MobjCollide", collideOrbi, i)
		addHook("MobjMoveCollide", collideOrbi, i)
	elseif i == MT_JAWZ then
		addHook("MobjCollide", collideJawz, i)
		addHook("MobjMoveCollide", collideJawz, i)
	end
end