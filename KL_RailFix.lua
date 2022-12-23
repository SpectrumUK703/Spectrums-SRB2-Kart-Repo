//It's just a copy of the Lua with all the "grind"s changed to "grindUT" lmao 
--grindUTRail (catmull-rom splines) lua by minenice
--thanks https://youtu.be/9_aJGUTePYo
--also these are totally not ride rails from splatoon 2 no not at all kek

--aka a deep look into my twisted masochistic mind

--TODO: MAKE DROPPED EGGBOXES HAVE NO GRAVITY ON RAILS		--TODO TODO: FUCKING FIX THE RANDOOM ASS C STACK OVERFLOW WHY

if (grindUTRails_initComplete) then return end

--apparently this makes shit faster? wtf?
local TICRATE = TICRATE
local FRACUNIT = FRACUNIT
local MAXSKINCOLORS = MAXSKINCOLORS
local ANG1 = ANG1
local k_sneakertimer = k_sneakertimer
local k_spinouttimer = k_spinouttimer
local k_wipeoutslow = k_wipeoutslow
local k_driftboost = k_driftboost
local k_floorboost = k_floorboost
local k_startboost = k_startboost
local k_itemamount = k_itemamount
local k_itemtype = k_itemtype
local k_rocketsneakertimer = k_rocketsneakertimer
local k_hyudorotimer = k_hyudorotimer
local k_drift = k_drift
local k_speedboost = k_speedboost
local k_accelboost = k_accelboost
local k_invincibilitytimer = k_invincibilitytimer
local k_growshrinktimer = k_growshrinktimer

--freeslot
freeslot(
	"MT_GRINDUTRAILCORE",
	"MT_GRINDUTRAILMUZZLE",
	"MT_GRINDUTRAILBASE",
	"MT_GRINDUTRAILPATH",
	"MT_GRINDUTRAILPATHTIP",
	
	"S_GRINDUTRAILCORE",
	"S_GRINDUTRAILMUZZLE",
	"S_GRINDUTRAILBASE",
	"S_GRINDUTRAILPATH",
	"S_GRINDUTRAILEND",
	"S_GRINDUTRAILPROP1",
	"S_GRINDUTRAILPROP2"
	
)

mobjinfo[MT_GRINDUTRAILCORE] = {
    doomednum = 2692,
    spawnstate = S_NULL,
    spawnhealth = 9000,
    radius = 256*FRACUNIT,
    height = 256*FRACUNIT,
    flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY|MF_SPECIAL
}
mobjinfo[MT_GRINDUTRAILPATH] = {
    doomednum = 2693,
    spawnstate = S_NULL,
    spawnhealth = 9000,
    radius = 24*FRACUNIT,
    height = 24*FRACUNIT,
    flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY|MF_SPECIAL
}
mobjinfo[MT_GRINDUTRAILPATHTIP] = {
    doomednum = -1,
    spawnstate = S_GRINDUTRAILEND,
    spawnhealth = 9000,
    radius = 32*FRACUNIT,
    height = 32*FRACUNIT,
    flags = MF_NOCLIP|MF_NOCLIPHEIGHT|MF_NOGRAVITY|MF_SCENERY
}
mobjinfo[MT_GRINDUTRAILMUZZLE] = {
    doomednum = -1,
    spawnstate = S_GRINDUTRAILMUZZLE,
    spawnhealth = 9000,
    radius = 1,
    height = 1,
    flags = MF_NOCLIP|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIPTHING|MF_SCENERY
}
mobjinfo[MT_GRINDUTRAILBASE] = {
    doomednum = -1,
    spawnstate = S_GRINDUTRAILBASE,
    spawnhealth = 9000,
    radius = 1,
    height = 1,
    flags = MF_NOCLIP|MF_NOGRAVITY|MF_NOCLIPHEIGHT|MF_NOCLIPTHING|MF_NOTHINK
}

states[S_GRINDUTRAILCORE] = {
        sprite = SPR_NULL,
        frame = A,
        tics = -1,
		nextstate = S_GRINDUTRAILCORE,
}
states[S_GRINDUTRAILMUZZLE] = {
        sprite = SPR_NULL,
        frame = A,
        tics = -1,
		nextstate = S_GRINDUTRAILMUZZLE,
}
states[S_GRINDUTRAILBASE] = {
        sprite = SPR_NULL,
        frame = A,
        tics = -1,
		nextstate = S_GRINDUTRAILBASE,
}
states[S_GRINDUTRAILPATH] = {
        sprite = SPR_NULL,
        frame = A,
        tics = -1,
		nextstate = S_GRINDUTRAILPATH,
}
states[S_GRINDUTRAILEND] = {
        sprite = SPR_NULL,
        frame = A,
        tics = -1,
		nextstate = S_GRINDUTRAILEND,
}
states[S_GRINDUTRAILPROP1] = {
        sprite = SPR_NULL,
        frame = A,
        tics = 1,
		nextstate = S_GRINDUTRAILPROP2,
}
states[S_GRINDUTRAILPROP2] = {
        sprite = SPR_NULL,
        frame = A,
        tics = 1,
		nextstate = S_GRINDUTRAILPROP1,
}


--these are catmull-rom splines btw
--GUESS WHO FUCKING FORGOT TO NETVAR THESE
rawset(_G, "grindUTRails_paths", {})	--arrays of path arrays. path arrays contain points.
rawset(_G, "grindUTRails_paths_mobjs", {})
rawset(_G, "grindUTRails_progSpeed", 40*FRACUNIT) --speed along the grindUT rails, either uses a custom value or this default value

addHook("NetVars", function(net)
	server.grindUTRails_paths = net(server.grindUTRails_paths)
	server.grindUTRails_paths_mobjs = net(server.grindUTRails_paths_mobjs)
end)

local function AT_sign(num)
	if num == 0 then return 0 end
	if num < 0 then return -1 end
	if num > 0 then return 1 end
end

local function K_GetKartDriftSparkValue(player)
	local kartspeed = player.kartspeed
	return (26*4 + kartspeed*2 + (9 - player.kartweight))*8;
end

local function K_MatchGenericExtraFlags(mo, master)
	--flipping
	--handle z shifting from there too. This is here since there's no reason not to flip us if needed when we do this anyway;
	mo.eflags = (mo.eflags & ~MFE_VERTICALFLIP)|(master.eflags & MFE_VERTICALFLIP)
	mo.flags2 = (mo.flags2 & ~MF2_OBJECTFLIP)|(master.flags2 & MF2_OBJECTFLIP)

	if (mo.eflags & MFE_VERTICALFLIP)
		mo.z = $ + master.height - FixedMul(master.scale, mo.height)
	end
	
	--visibility (usually for hyudoro)
	mo.flags2 = (mo.flags2 & ~MF2_DONTDRAW)|(master.flags2 & MF2_DONTDRAW)
	mo.eflags = (mo.eflags & ~MFE_DRAWONLYFORP1)|(master.eflags & MFE_DRAWONLYFORP1)
	mo.eflags = (mo.eflags & ~MFE_DRAWONLYFORP2)|(master.eflags & MFE_DRAWONLYFORP2)
	mo.eflags = (mo.eflags & ~MFE_DRAWONLYFORP3)|(master.eflags & MFE_DRAWONLYFORP3)
	mo.eflags = (mo.eflags & ~MFE_DRAWONLYFORP4)|(master.eflags & MFE_DRAWONLYFORP4)
end

local function K_UpdateHnextList(player, clean)
	local work = player.mo

	if not work.valid then return end

	local nextwork = work.hnext
	work = nextwork

	while work and work.valid do
		nextwork = work.hnext
		if (clean == false and (not work.movedir or work.movedir <= player.kartstuff[k_itemamount])) then continue end
		P_RemoveMobj(work)
		work = nextwork
	end
end

--WHO'S READY FOR FIXED POINT MATH HELL
--I KNOW I AM
--WOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
local function getSplinePoint(points, weight, looped)
	--points is an array of the points in the spline, weight is a fixed point number, looped is a bool, 
	--not like grindUT rails will ever need to be looped, but just in case you want looped paths for something else it can be useful
	local p0, p1, p2, p3
	
	if looped then	--why the fuck not use this for cars or something idk
		p1 = FixedInt(weight) + 1
		p2 = (p1 + 1) % table.getn(points)
		p3 = (p2 + 1) % table.getn(points)
		p0 = p1 >= 1 and p1 - 1 or table.getn(points) - 1	--kek
	else
		p1 = FixedInt(weight) + 1
		
		if p1 == table.getn(points) then
			p2 = p1
		else
			p2 = p1 + 1
		end
		
		if p2 == table.getn(points) then
			p3 = p2
		else
			p3 = p2 + 1
		end
		
		p0 = p1 - 1
	end
	
	
	weight = $ - FixedFloor($)
	
	--cache me my shit
	--squared and cubed weight
	local weightSqu = FixedMul(weight, weight)
	local weightCub = FixedMul(weightSqu, weight)
	
	--now we do the crazy math shit
	--this is where I wished I could use fucking floats for once kek
	local q1 = -weightCub + FixedMul(2*FRACUNIT, weightSqu) - weight
	local q2 = FixedMul(3*FRACUNIT, weightCub) - FixedMul(5*FRACUNIT, weightSqu) + 2*FRACUNIT
	local q3 = FixedMul(-3*FRACUNIT, weightCub) + FixedMul(4*FRACUNIT, weightSqu) + weight
	local q4 = weightCub - weightSqu
	
	--now calculate the points based on the values we just miraculously got
	--REMEMBER WE'RE WORKING IN 3D HERE
	local rx = FixedDiv( FixedMul(points[p0].x, q1) + FixedMul(points[p1].x, q2 ) + FixedMul(points[p2].x, q3 ) + FixedMul(points[p3].x, q4 ), 2*FRACUNIT )
	local ry = FixedDiv( FixedMul(points[p0].y, q1) + FixedMul(points[p1].y, q2 ) + FixedMul(points[p2].y, q3 ) + FixedMul(points[p3].y, q4 ), 2*FRACUNIT )
	local rz = FixedDiv( FixedMul(points[p0].z, q1) + FixedMul(points[p1].z, q2 ) + FixedMul(points[p2].z, q3 ) + FixedMul(points[p3].z, q4 ), 2*FRACUNIT )
	
	--return the point as a table cause this shit expensive maybe
	
	local t = {x = rx, y = ry, z = rz}
	--print(t.x/FRACUNIT + ", " + t.y/FRACUNIT + ", " + t.z/FRACUNIT)
	return t
end

--get a weight delta that corresponds to a fixed velocity
--because normalized coordinates fuck with your mind
local function getNextWeight(path, currentPos, currentWeight, vel)
	local nextPos = getSplinePoint(path, currentWeight + (FRACUNIT/8))
	
	--print(currentWeight)
	--print(currentPos.x, currentPos.y, currentPos.z)
	--print(nextPos.x, nextPos.y, nextPos.z)
	
	local dX = nextPos.x - currentPos.x
	local dY = nextPos.y - currentPos.y
	local dZ = nextPos.z - currentPos.z
	
	--oh my god I'm fucking dumb
	--local dist = P_AproxDistance(P_AproxDistance(dx, dy), dz)
	local dist = P_AproxDistance(P_AproxDistance(dX, dY), dZ)	--three deeeeeeeeeeeee
	--print(dist)
	
	local ratio = FixedDiv(vel, dist)
	
	--print(ratio)
	
	return(currentWeight + FixedMul(FRACUNIT/8, ratio))
end

--now then here's we figure out how the rail setup will work in the first place
--the thing angle determines the id of the control point in the curve
--the thing parameter (extra info) and the extra and objectspecial flags determine which path the control point belongs to 
--aka the id of the path (this means 64 paths in total, wow)
--this feels very hacky but how the fuck else can I do this without pulling a battle plus

local function searchPaths()
	for thing in mapthings.iterate do
		
		if thing.type ~= 2692 and thing.type ~= 2693 then continue end	--don't waste our fucking time
		
		--find path ID of thing
		local pathId = thing.extrainfo
		local finFlags = 0
		if (thing.options & 1) then pathId = $ + 16 end
		if (thing.options & 4) then pathId = $ + 32 end
		
		--print(pathId)
		
		--seems like you've had the same shit as me amper
		local sec = R_PointInSubsector(thing.x*FRACUNIT, thing.y*FRACUNIT).sector
		
		local floorZ
		if sec.f_slope then
			floorZ = P_GetZAt(sec.f_slope, thing.x*FRACUNIT, thing.y*FRACUNIT)
		else
			floorZ = sec.floorheight
		end
		
		--i am in pain
		local properZ = floorZ + (thing.options>>4)*FRACUNIT
		--print(properZ)
		
		if thing.type == 2692 then
			if server.grindUTRails_paths[pathId] == nil then
				server.grindUTRails_paths[pathId] = {}
			end
			if server.grindUTRails_paths_mobjs[pathId] == nil then
				server.grindUTRails_paths_mobjs[pathId] = {}
			end
			if (thing.angle & 1) then finFlags = $|1 end		--core: rail is deactivated (items or lua function to activate)
			if (thing.options & 8) then finFlags = $|2 end		--core: is in air (spawns propeller instead of base), path: RESERVED
			
			server.grindUTRails_paths[pathId][0] = {x = thing.x*FRACUNIT, y = thing.y*FRACUNIT, z = properZ + 32*FRACUNIT, flags = finFlags}
			server.grindUTRails_paths[pathId][1] = {x = thing.x*FRACUNIT, y = thing.y*FRACUNIT, z = properZ + 32*FRACUNIT, flags = finFlags}
		elseif thing.type == 2693 then	--Id 0 is already used by the grindUT rail core
			if server.grindUTRails_paths[pathId] == nil then
				server.grindUTRails_paths[pathId] = {}
			end
			if server.grindUTRails_paths_mobjs[pathId] == nil then
				server.grindUTRails_paths_mobjs[pathId] = {}
			end
			if (thing.options & 2) then finFlags = $|1 end		--core: NONE path: flipped rail (TODO)
			if (thing.options & 8) then finFlags = $|2 end		--core: is in air (spawns propeller instead of base), path: RESERVED
			server.grindUTRails_paths[pathId][(thing.angle + 2)] = {x = thing.x*FRACUNIT, y = thing.y*FRACUNIT, z = properZ, flags = finFlags}
			
		end
	end
end

--wow that was easier than I thought I hope
--NOPE IT WASN'T

--now we create the rails in the world
--for every rail in the global rail array:
--create the rail's starting point (Core, Core Base, and Core Muzzle)
--create the actual rail by:
--going through the path and stepping in small amounts, creating a GRINDUTRAILPATH object at that location
--we also create a GRINDUTRAILEND object at the end of the path elsewhere

local function createGrindUTRails(looped)
	for id, path in pairs(server.grindUTRails_paths) do
		--if (path[0].flags & 1) then continue end
		local currWeight = 0
		local currPos = getSplinePoint(path, currWeight)
		for pointNum, point in pairs(path) do
			local iter = 0
			if pointNum > table.getn(path) then continue end
			--getNextWeight(path, currPos, currWeight, 24*FRACUNIT) < table.getn(path)*FRACUNIT
			while getNextWeight(path, currPos, currWeight, 32*FRACUNIT) < (pointNum * FRACUNIT - FRACUNIT) do
				
				iter = $ + 1
				
				currWeight = getNextWeight(path, currPos, $, 32*FRACUNIT)
				--print("weight is")
				--print(currWeight)
				
				--print("getting pos for iter " + iter + " of point " + pointNum)
				currPos = getSplinePoint(path, currWeight, looped)
				--print("FUCK YOUUUUUUUUU")
				
				local pathPoint = P_SpawnMobj(currPos.x, currPos.y, currPos.z, MT_GRINDUTRAILPATH)
				pathPoint.color = SKINCOLOR_GREY
				pathPoint.pathWeight = currWeight
				pathPoint.pathId = id
				pathPoint.state = S_GRINDUTRAILPATH
				table.insert(server.grindUTRails_paths_mobjs[id], pathPoint)
			end
		end
	end
end

local function createRailCore(path, id)
	local pos = server.grindUTRails_paths[id][0]
	
	local core = P_SpawnMobj(pos.x, pos.y, pos.z - 32*FRACUNIT, MT_GRINDUTRAILCORE)
	core.state = S_GRINDUTRAILCORE
	core.pathId = id
	if (server.grindUTRails_paths[id][0].flags & 1) then
		core.color = 21 + leveltime/4 % 5
	else
		core.color = 1 + leveltime/4 % 5
	end
	
	--create the base / propeller
	if (pos.flags & 2) then
		local mpos = getSplinePoint(path, getNextWeight(path, pos, 0, 30*FRACUNIT))
		local mang = R_PointToAngle2(pos.x, pos.y, mpos.x, mpos.y)
		local prop = P_SpawnMobj(mpos.x + P_ReturnThrustX(prop, mang + 180*ANG1, 58*FRACUNIT), mpos.y + P_ReturnThrustY(prop, mang + 180*ANG1, 58*FRACUNIT), mpos.z, MT_GRINDUTRAILMUZZLE)
		prop.angle = mang + 90*ANG1
		prop.state = S_GRINDUTRAILPROP1
		prop.scale = 3*FRACUNIT/4
	else
		local i = 0
		while (i <= 8) do
			local ang = (360 * (ANG1 / 8)) * i
			local part = P_SpawnMobj(pos.x + FixedMul(24*FRACUNIT + FRACUNIT/2, cos(ang)), pos.y + FixedMul(24*FRACUNIT + FRACUNIT/2, sin(ang)), pos.z - 32*FRACUNIT, MT_GRINDUTRAILBASE)
			part.angle = ang + 90*ANG1
			i = $ + 1
		end
	end
	
	--create the muzzle
	local mpos = getSplinePoint(path, getNextWeight(path, pos, 0, 30*FRACUNIT))
	local muzzle = P_SpawnMobj(mpos.x, mpos.y, mpos.z, MT_GRINDUTRAILMUZZLE)
	muzzle.angle = R_PointToAngle2(pos.x, pos.y, mpos.x, mpos.y) + 90*ANG1
end

--TODO: SPAWNING RAILS MID-RACE YOU FUCK
local function createRailEnds(path, id)
	local pos = path[table.getn(path)]
	--print(pos)
	local mpos = getSplinePoint(path, getNextWeight(path, pos, (table.getn(path)-1)*FRACUNIT, -FRACUNIT/8))
	local ang = R_PointToAngle2(pos.x, pos.y, mpos.x, mpos.y) + 180*ANG1
	local tip = P_SpawnMobj(pos.x + FixedMul(32*FRACUNIT, cos(ang)), pos.y + FixedMul(32*FRACUNIT, sin(ang)), pos.z, MT_GRINDUTRAILPATH)
	tip.angle = ang
	tip.state = S_GRINDUTRAILEND
	tip.color = SKINCOLOR_SILVER
	tip.pathId = id
	--S_StartSound(tip, sfx_griact)
end

local function createRailSpawner(path, id)
	local pos = server.grindUTRails_paths[id][0]
	--pos.flags = $&~1
	--print(pos.flags)
	local mpos = getSplinePoint(server.grindUTRails_paths[id], getNextWeight(server.grindUTRails_paths[id], pos, 0, 32*FRACUNIT))
	local ang = R_PointToAngle2(pos.x, pos.y, mpos.x, mpos.y)
	local tip = P_SpawnMobj(pos.x, pos.y, pos.z, MT_GRINDUTRAILPATHTIP)
	tip.angle = ang
	tip.state = S_GRINDUTRAILEND
	tip.color = SKINCOLOR_SILVER
	tip.createProg = getNextWeight(server.grindUTRails_paths[id], pos, 0, 32*FRACUNIT )
	tip.lastProg = getNextWeight(server.grindUTRails_paths[id], pos, 0, 32*FRACUNIT )
	tip.pathId = id
	tip.createTics = 0
end

local function deactivateRail(id)
	--server.grindUTRails_paths[id][0].flags = ($ &~ 1)
	for i, mo in pairs(server.grindUTRails_paths_mobjs) do
		P_RemoveMobj(mo)
	end
end

local function railSpawnerFunc(mo)
	if mo and mo.valid then
		--rail spawner
		if leveltime > 8 then
			if mo.createTics % 146 == 0 then	--repeat sound every 146 tics
				--S_StartSound(mo, sfx_gricon)
			end
			mo.createTics = $+1
			local grindUTFin = false
			local gpos = getSplinePoint(server.grindUTRails_paths[mo.pathId], mo.createProg, false)
			--print(gpos.x)
			if FixedInt(getNextWeight(server.grindUTRails_paths[mo.pathId], gpos, mo.createProg, FixedMul(grindUTRails_progSpeed + 20*FRACUNIT, 5*FRACUNIT/3) )) >= table.getn(server.grindUTRails_paths[mo.pathId]) - 1 then grindUTFin = true end
			
			if not grindUTFin then
				mo.createProg = getNextWeight(server.grindUTRails_paths[mo.pathId], gpos, $, FixedMul(grindUTRails_progSpeed + 20*FRACUNIT, 5*FRACUNIT/3) )
				local npos = getSplinePoint(server.grindUTRails_paths[mo.pathId], mo.createProg)
				P_TeleportMove(mo, gpos.x, gpos.y, gpos.z + FRACUNIT*8)
				local movang = R_PointToAngle2(gpos.x, gpos.y, npos.x, npos.y)
				P_InstaThrust(mo, movang, FixedMul(grindUTRails_progSpeed + 16*FRACUNIT, 5*FRACUNIT/3) )
				mo.angle = movang
				mo.momz = npos.z - gpos.z
				
				repeat
					--print("weight is")
					--print(currWeight)
					
					--print("getting pos for iter " + iter + " of point " + pointNum)
					gpos = getSplinePoint(server.grindUTRails_paths[mo.pathId], mo.lastProg, false)
					--print("FUCK YOUUUUUUUUU")
					
					local pathPoint = P_SpawnMobj(gpos.x, gpos.y, gpos.z, MT_GRINDUTRAILPATH)
					pathPoint.color = SKINCOLOR_GREY
					pathPoint.pathWeight = mo.lastProg
					pathPoint.pathId = mo.pathId
					pathPoint.state = S_GRINDUTRAILPATH
					table.insert(server.grindUTRails_paths_mobjs[mo.pathId], pathPoint)
					mo.lastProg = getNextWeight(server.grindUTRails_paths[mo.pathId], gpos, $, 32*FRACUNIT)
				until (getNextWeight(server.grindUTRails_paths[mo.pathId], gpos, mo.lastProg, 32*FRACUNIT) >= mo.createProg)
			else
				repeat
					--print("weight is")
					--print(currWeight)
					
					--print("getting pos for iter " + iter + " of point " + pointNum)
					gpos = getSplinePoint(server.grindUTRails_paths[mo.pathId], mo.lastProg, false)
					--print("FUCK YOUUUUUUUUU")
					
					local pathPoint = P_SpawnMobj(gpos.x, gpos.y, gpos.z, MT_GRINDUTRAILPATH)
					pathPoint.color = SKINCOLOR_GREY
					pathPoint.pathWeight = mo.lastProg
					pathPoint.pathId = mo.pathId
					pathPoint.state = S_GRINDUTRAILPATH
					table.insert(server.grindUTRails_paths_mobjs[mo.pathId], pathPoint)
					mo.lastProg = getNextWeight(server.grindUTRails_paths[mo.pathId], gpos, $, 32*FRACUNIT)
				until (getNextWeight(server.grindUTRails_paths[mo.pathId], gpos, mo.lastProg, 32*FRACUNIT) >= (table.getn(server.grindUTRails_paths[mo.pathId]) * FRACUNIT - FRACUNIT))
				S_StopSound(mo)
				createRailEnds(server.grindUTRails_paths[mo.pathId], mo.pathId)
				P_RemoveMobj(mo)
			end
		end
	end
end

addHook("MobjThinker", railSpawnerFunc, MT_GRINDUTRAILPATHTIP)


local function railCoreThinker(mo)
	if mo and mo.valid and (server.grindUTRails_paths ~= nil and server.grindUTRails_paths[mo.pathId] ~= nil) then
		if (server.grindUTRails_paths[mo.pathId][0].flags & 1) then
			mo.color = 21 + leveltime/4 % 5
		else
			mo.color = 1 + leveltime/4 % 5
		end
	end
end

addHook("MobjThinker", railCoreThinker, MT_GRINDUTRAILCORE)

local function playFunc(mo)
	if leveltime ~= 0 then
		if (mo.player and mo.valid) then
			local p = mo.player
			if not p.railjumped then p.railjumped = false end
			if p.railItemUnheld == nil then p.railItemUnheld = true end
			
			if (not (p.cmd.buttons & BT_BRAKE)) and p.railjumped and (P_IsObjectOnGround(mo) or p.grindUTing) then
				p.railjumped = false
			end
			
			if not p.grindUTing then
				--if (p.cmd.buttons & BT_CUSTOM1) then		--debug
				--	p.grindUTing = true
				--	p.grindUTingrail = 0
				--	p.grindUTprog = 0
				--end
			else
				if not p.grindUTprog then
					p.grindUTprog = 0
				end
				if p.grindUTing then
					local grindUTFin = false
					
					local gpos = getSplinePoint(server.grindUTRails_paths[p.grindUTingrail], p.grindUTprog)
					if FixedInt(getNextWeight(server.grindUTRails_paths[p.grindUTingrail], gpos, p.grindUTprog, FixedMul(grindUTRails_progSpeed, FixedMul(p.kartstuff[k_boostpower] + p.kartstuff[k_speedboost], p.mo.scale)) )) >= table.getn(server.grindUTRails_paths[p.grindUTingrail]) - 1 then grindUTFin = true end
					--if (server.grindUTRails_paths[p.grindUTingrail][0].flags & 1) then grindUTFin = true end
					
					if (p.cmd.buttons & BT_BRAKE) and p.railjumped == false and p.grindUTprog > getNextWeight(server.grindUTRails_paths[p.grindUTingrail], server.grindUTRails_paths[p.grindUTingrail][0], 0, 256*FRACUNIT) then
						mo.momz = 16*FRACUNIT
						P_InstaThrust(mo, mo.angle, 10*FRACUNIT)
						p.kartstuff[k_pogospring] = 2
						p.grindUTing = false
						grindUTFin = true
						p.railjumped = true
					end
					
					if not grindUTFin then	--pain defined below
						if p.kartstuff[k_pogospring] ~= 0 then p.kartstuff[k_pogospring] = 0 end
						local ATTACK_IS_DOWN = ((p.cmd.buttons & BT_ATTACK) and p.railItemUnheld)
						local HOLDING_ITEM = (p.kartstuff[k_itemheld] or p.kartstuff[k_eggmanheld])
						local NO_HYUDORO = (p.kartstuff[k_stolentimer] == 0 and p.kartstuff[k_stealingtimer] == 0)
						if p.railItemUnheld == false then	--fuck me pflags ain't workin
							if not (p.cmd.buttons & BT_ATTACK) then
								p.railItemUnheld = true
							end
						end
						if ATTACK_IS_DOWN and NO_HYUDORO and not HOLDING_ITEM then
							--print("using item on rail")
							if p.railItemUnheld then
								p.railItemUnheld = false
							end
							if p.kartstuff[k_itemtype] == 1 then
								--print("boosted on rail")
								K_DoSneaker(p, 1)
								K_PlayBoostTaunt(p.mo)
								p.kartstuff[k_itemamount] = $ - 1
							end
							if p.kartstuff[k_rocketsneakertimer] > 1 then
								--print("sneakered on rail")
								K_DoSneaker(p, 2)
								K_PlayBoostTaunt(p.mo)
								p.kartstuff[k_rocketsneakertimer] = $ - 2*TICRATE
								if p.kartstuff[k_rocketsneakertimer] < 1 then
									p.kartstuff[k_rocketsneakertimer] = 1
								end
							end
							if p.kartstuff[k_itemtype] == 2 and p.kartstuff[k_rocketsneakertimer] == 0 then
								--oh god no pls no
								--TODO: DO THE THING THAT HAPPENS WHEN SPAWNING ROCKET SNEAKERS I MAY HAVE TO USE OLD HOSTMOD SHIT WHYYYYYYYYYYYYY
								K_PlayBoostTaunt(p.mo);
								--S_StartSound(p.mo, sfx_s3k3a);

								p.kartstuff[k_rocketsneakertimer] = (8*3*TICRATE)
								p.kartstuff[k_itemamount] = $-1
								K_UpdateHnextList(p, true)	--TODO
								--TODO: FINISH THIS, ADD LAUNCHING BEHAVIOUR FOR MEGA AND BOOST RAMMING, ADD GLOWS TO THE BOOST PANELS IN THE MAP
								
								local i = 0
								local prev = mo
								while i < 2 do
									local moR = P_SpawnMobj(mo.x, mo.y, mo.z, MT_ROCKETSNEAKER)
									K_MatchGenericExtraFlags(moR, mo)
									moR.flags = $ | MF_NOCLIPTHING
									moR.angle = mo.angle
									moR.threshold = 10
									moR.movecount = i % 2
									moR.movedir = i + 1
									moR.lastlook = i + 1
									moR.target = mo
									moR.hprev = prev
									prev.hnext = moR
									prev = moR
									i = $ + 1
								end
							end
						end
						
						if leveltime % 3 == 0 then
							--S_StartSound(mo, sfx_cdfm17)
						end
						p.grindUTprog = getNextWeight(server.grindUTRails_paths[p.grindUTingrail], gpos, $, FixedMul(grindUTRails_progSpeed, FixedMul(p.kartstuff[k_boostpower] + p.kartstuff[k_speedboost], p.mo.scale) ))
						local npos = getSplinePoint(server.grindUTRails_paths[p.grindUTingrail], p.grindUTprog)
						P_TeleportMove(mo, gpos.x, gpos.y, gpos.z + FRACUNIT*8)
						local movang = R_PointToAngle2(gpos.x, gpos.y, npos.x, npos.y)
						P_InstaThrust(mo, movang, FixedMul(grindUTRails_progSpeed, FixedMul(p.kartstuff[k_boostpower] + p.kartstuff[k_speedboost], p.mo.scale) ))
						mo.angle = movang
						p.drawangle = movang + 45*ANG1
						mo.momz = npos.z - gpos.z
						mo.state = S_KART_DRIFT2_R
						
						--fancy sparks make my head commit die
						--print("spawn sparks")
						local sparks = P_SpawnMobj(gpos.x, gpos.y, gpos.z, MT_SPARK)
						sparks.scale = mo.scale
						sparks.momx = FRACUNIT*P_RandomRange(-5, 5)
						sparks.momy = FRACUNIT*P_RandomRange(-5, 5)
						sparks.momz = FRACUNIT*P_RandomRange(10, 16)
						sparks.colorized = true
						K_MatchGenericExtraFlags(sparks, mo)
						if p.kartstuff[k_driftcharge] >= K_GetKartDriftSparkValue(p) * 4 then
							sparks.color = 1 + leveltime % (MAXSKINCOLORS - 1)
						elseif p.kartstuff[k_driftcharge] >= K_GetKartDriftSparkValue(p) * 2 then
							sparks.color = SKINCOLOR_ORANGE
						elseif p.kartstuff[k_driftcharge] >= K_GetKartDriftSparkValue(p) then
							sparks.color = SKINCOLOR_SAPPHIRE
						else
							sparks.color = SKINCOLOR_SILVER
						end
					else
						if not (p.cmd.buttons & BT_BRAKE) then		--just makes finishing a rail more consistent
							gpos = getSplinePoint(server.grindUTRails_paths[p.grindUTingrail], (table.getn(server.grindUTRails_paths[p.grindUTingrail]) - 1)*FRACUNIT)
							local npos = getSplinePoint(server.grindUTRails_paths[p.grindUTingrail], (table.getn(server.grindUTRails_paths[p.grindUTingrail] )- 1)*FRACUNIT - FRACUNIT/32)
							P_TeleportMove(mo, gpos.x, gpos.y, gpos.z + FRACUNIT*8)
							local movang = R_PointToAngle2(gpos.x, gpos.y, npos.x, npos.y) - 180*ANG1
							P_InstaThrust(mo, movang, 28*FRACUNIT)
							mo.angle = movang
						else
							P_InstaThrust(mo, mo.angle, 28*FRACUNIT)
						end
						mo.momz = 24*FRACUNIT
						p.kartstuff[k_pogospring] = 2
						--S_StartSound(mo, sfx_griend)
						p.grindUTing = false
						--print("finished rail")
					end
					
					
				end
			end
		end
	end
end

addHook("MobjThinker", playFunc, MT_PLAYER)

local function railMapLoad()	--clear all of the paths
	server.grindUTRails_paths = {}
	server.grindUTRails_paths_mobjs = {}
	searchPaths()
	--createGrindUTRails()
	for id, path in pairs(server.grindUTRails_paths) do
		createRailCore(path, id)
		--createRailEnds(path, id)
		--if not (path[0].flags & 1) then
			createRailSpawner(path, id)
		--end
	end
	for p in players.iterate
		p.grindUTing = false
		p.grindUTingrail = 0
		p.grindUTprog = 0
	end
	if mapheaderinfo[gamemap].grindUTrails_grindUTspeed then
		grindUTRails_progSpeed = tonumber(mapheaderinfo[gamemap].grindUTrails_grindUTspeed) * FRACUNIT
	else
		grindUTRails_progSpeed = 50*FRACUNIT
	end
end

addHook("MapLoad", railMapLoad)

local function playerRailDie(mo)
	if mo and mo.player then
		local p = mo.player
		p.grindUTing = false
		p.grindUTingrail = 0
		p.grindUTprog = 0
	end
end

addHook("MobjDeath", playerRailDie, MT_PLAYER)

local function playTouchCoreFunc(mo, toucher)
	if toucher and toucher.player and toucher.valid then
		local p = toucher.player
		
		if (p.kartstuff[k_sneakertimer] or p.kartstuff[k_growshrinktimer] > 0 or p.kartstuff[k_invincibilitytimer] > 0) and (not p.grindUTing) then
    p.kartstuff[k_pogospring] = 0
    p.grindUTing = true
    p.grindUTingrail = mo.pathId
    p.grindUTprog = 0
    --S_StartSound(p.mo, sfx_grilan)
end
	end
	return true
end

addHook("TouchSpecial", playTouchCoreFunc, MT_GRINDUTRAILCORE)


--haha orbi and shark nuke go boing
local function railCoreItemInter(mo, toucher)
	if toucher and toucher.isOnRail == true then return false end
	if mo and mo.z - toucher.height <= toucher.z and toucher.z <= mo.z + mo.height + toucher.height then
		--TODO: rail activation
		if toucher.type == MT_ORBINAUT or toucher.type == MT_JAWZ or toucher.type == MT_JAWZ_DUD or toucher.type == MT_BALLHOG or toucher.type == MT_SINK then
			--if (server.grindUTRails_paths[mo.pathId][0].flags & 1) then
				createRailSpawner(server.grindUTRails_paths[mo.pathId], mo.pathId)
				--S_StartSound(mo, sfx_grion)
			--end
			toucher.momz = 24*FRACUNIT
			--S_StartSound(toucher, sfx_grilan)
		end
		if toucher.type == MT_EGGMANITEM then
			toucher.z = mo.z + 65*FRACUNIT
			toucher.momx = 0
			toucher.momy = 0
			toucher.momz = 0
			toucher.flags = $|MF_NOGRAVITY
			toucher.isOnRail = true
		end
	end
end

addHook("MobjCollide", railCoreItemInter, MT_GRINDUTRAILCORE)

local function railPathPlayInter(mo, toucher)
	if toucher and toucher.z < mo.z + 10*FRACUNIT then return true end
	if mo and mo.pathId == nil then return true end
	if mo and mo.state == S_GRINDUTRAILEND then return true end
	if mo and mo.pathWeight >= table.getn(server.grindUTRails_paths[mo.pathId])*FRACUNIT - FRACUNIT/10 then return true end
	if toucher and toucher.player and toucher.valid and toucher.momz < 0 and mo.state ~= S_GRINDUTRAILEND and mo.pathId ~= nil then
		--print(mo.pathId)
		local p = toucher.player
		if not p.grindUTing then
			p.kartstuff[k_pogospring] = 0
			p.grindUTing = true
			p.grindUTingrail = mo.pathId
			p.grindUTprog = mo.pathWeight
			--S_StartSound(p.mo, sfx_grilan)
		end
	end
	return true
end

addHook("TouchSpecial", railPathPlayInter, MT_GRINDUTRAILPATH)

local function railPathItemInter(mo, toucher)
	--if mo.pathId == nil then return end
	--if mo.state == S_GRINDUTRAILEND then return false end
	if toucher and toucher.isOnRail == true then return false end
	if mo and mo.z - toucher.height <= toucher.z and toucher.z <= mo.z + mo.height + toucher.height and toucher.momz < 0 then
		if toucher.type == MT_ORBINAUT or toucher.type == MT_JAWZ or toucher.type == MT_JAWZ_DUD then
			toucher.momz = 24*FRACUNIT
			toucher.z = mo.z + 8*FRACUNIT
			--S_StartSound(toucher, sfx_grilan)
		end
		if toucher.type == MT_SINK then
			toucher.momz = 24*FRACUNIT
			toucher.z = mo.z + 8*FRACUNIT
			--S_StartSound(toucher, sfx_grilan)
		end
		if toucher.type == MT_EGGMANITEM then
			toucher.isOnRail = true
			toucher.z = mo.z + 48*FRACUNIT
			toucher.momx = 0
			toucher.momy = 0
			toucher.momz = 0
			toucher.flags = $|MF_NOGRAVITY
		end
	end
end

addHook("MobjCollide", railPathItemInter, MT_GRINDUTRAILPATH)

local function railSpin(p, inflictor, source)
	if p and p.grindUTing then
		p.mo.momz = 24*FRACUNIT
		p.grindUTing = false
		P_InstaThrust(p.mo, p.mo.angle, 8*FRACUNIT)
		--grindUTFin = true
	end
end

addHook("PlayerSpin", railSpin)

local function railExplode(p, inflictor, source)
	if p and p.grindUTing then
		p.mo.momz = 48*FRACUNIT
		p.grindUTing = false
		P_InstaThrust(p.mo, p.mo.angle, 0)
		--grindUTFin = true
	end
end

addHook("PlayerExplode", railExplode)

--squish becomes a ram
local function railSquish(p, inflictor, source)
	if p and p.grindUTing then
		p.grindUTing = false
		p.mo.momz = 24*FRACUNIT
		P_InstaThrust(p.mo, p.mo.angle, 0)
		p.kartstuff[k_squishedtimer] = 0
	end
end

addHook("PlayerSquish", railSquish)

--boost ramming
local function railRam(mo, toucher)
	if mo and (not mo.player) then return end
	if toucher and (not toucher.player) then return end
	local p = mo.player 
	local tp = toucher.player
	if not (p.grindUTing and tp.grindUTing) then return end
	if p and tp and p.kartstuff[k_speedboost] > tp.kartstuff[k_speedboost] then
		if mo and toucher and mo.z - toucher.height <= toucher.z and toucher.z <= mo.z + mo.height + toucher.height then
			--P_InstaThrust(tp.mo, R_PointToAngle2(tp.x, tp.y, p.x, p.y) - 180*ANG1, 3*p.speed/4)
			tp.mo.momz = 24*FRACUNIT
			tp.grindUTing = false
		end
	end
end

addHook("MobjCollide", railRam, MT_PLAYER)

rawset(_G, "grindUTRails_initComplete", true)

--someone remind me these rails look kinda like pasta and meatballs I had a terrible idea