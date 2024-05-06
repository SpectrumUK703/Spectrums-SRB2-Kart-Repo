local TRICKMOMZRAMP = 30
local TRICKLAG = 9
local TRICKDELAY = TICRATE/4
local KART_FULLTURN = 800
local TRICKSTATE_NONE = 0
local TRICKSTATE_READY = 1
local TRICKSTATE_FORWARD = 2
local TRICKSTATE_RIGHT = 3
local TRICKSTATE_LEFT = 4
local TRICKSTATE_BACK = 5
local GROW_PHYSICS_SCALE = (3*FRACUNIT/2)
local SHRINK_PHYSICS_SCALE = (3*FRACUNIT/4)
local GROW_SCALE = (2*FRACUNIT)
local SHRINK_SCALE = (FRACUNIT/2)

local function K_GrowShrinkSpeedMul(player)
	local scaleDiff = player.mo.scale - mapobjectscale
	local playerScale = FixedDiv(player.mo.scale, mapobjectscale)
	local speedMul = FRACUNIT

	if (scaleDiff > 0)
		speedMul = FixedDiv(FixedMul(playerScale, GROW_PHYSICS_SCALE), GROW_SCALE)
	elseif (scaleDiff < 0)
		speedMul = FixedDiv(FixedMul(playerScale, SHRINK_PHYSICS_SCALE), SHRINK_SCALE)
	end

	return speedMul
end

addHook("ThinkFrame", function()
	local cmd
	local lr
	local momz
	local invertscale
	local speedmult
	local basespeed
	local speed
	local tornadotrickspeed
	local angledelta
	local baseangle
	local aimingcompare
	local TRICKTHRESHOLD
	for p in players.iterate
	if p.trickpanel == TRICKSTATE_READY
		cmd = p.cmd
		lr = ANGLE_45
		momz = FixedDiv(p.mo.momz, mapobjectscale)	// bring momz back to scale...
		invertscale = FixedDiv(FRACUNIT, K_GrowShrinkSpeedMul(p))
		speedmult = max(0, FRACUNIT - abs(momz)/TRICKMOMZRAMP)
		basespeed = FixedMul(invertscale, K_GetKartSpeed(p, false, false))
		speed = FixedMul(invertscale, FixedMul(speedmult, P_AproxDistance(p.mo.momx, p.mo.momy)))
		if (momz >= -10*FRACUNIT) and p.tricktime >= TRICKDELAY and (cmd.buttons & BT_DRIFT)
			p.pflags = $ & ~PF_TRICKDELAY
			tornadotrickspeed = ANG30
			angledelta = FixedAngle(36*FRACUNIT)
			baseangle = p.mo.angle + angledelta/2
			aimingcompare = abs(cmd.throwdir) - abs(cmd.turning)
			TRICKTHRESHOLD = (KART_FULLTURN/2)
			if aimingcompare < -TRICKTHRESHOLD	// side trick
				S_StartSoundAtVolume(p.mo, sfx_trick0, 255/2)
				p.dotrickfx = true

				p.trickboostdecay = min(TICRATE*3/4, abs(momz/FRACUNIT))

				if (cmd.turning > 0)
					P_InstaThrust(p.mo, p.mo.angle + lr, max(basespeed, speed*5/2))
					p.trickpanel = TRICKSTATE_RIGHT

					if p.trickIndicator and p.trickIndicator.valid
						p.trickIndicator.rollangle = ANGLE_270
					end

					p.drawangle = $-ANGLE_45
					p.mo.state = S_KART_FAST_LOOK_L
				else
					P_InstaThrust(p.mo, p.mo.angle - lr, max(basespeed, speed*5/2))
					p.trickpanel = TRICKSTATE_LEFT

					if p.trickIndicator and p.trickIndicator.valid
						p.trickIndicator.rollangle = ANGLE_90
					end

					tornadotrickspeed = InvAngle(tornadotrickspeed)

					p.drawangle = $+ANGLE_45
					p.mo.state = S_KART_FAST_LOOK_R
				end
			elseif (aimingcompare > TRICKTHRESHOLD) // forward/back trick
				S_StartSoundAtVolume(p.mo, sfx_trick0, 255/2)
				p.dotrickfx = true

				p.trickboostdecay = min(TICRATE*3/4, abs(momz/FRACUNIT))

				if (cmd.throwdir > 0)
					if (p.mo.momz * P_MobjFlip(p.mo) > 0)
						p.mo.momz = 0
					end

					P_InstaThrust(p.mo, p.mo.angle, max(basespeed, speed*3))
					p.trickpanel = TRICKSTATE_FORWARD

					if p.trickIndicator and p.trickIndicator.valid
						p.trickIndicator.rollangle = 0
					end

					p.mo.state = S_KART_FAST
				elseif (cmd.throwdir < 0)
					p.mo.momx = $/3
					p.mo.momy = $/3

					if (p.mo.momz * P_MobjFlip(p.mo) <= 0)
						p.mo.momz = 0
					end

					p.mo.momz = $+P_MobjFlip(p.mo)*48*mapobjectscale
					p.trickpanel = TRICKSTATE_BACK

					if p.trickIndicator and p.trickIndicator.valid
						p.trickIndicator.rollangle = ANGLE_180
					end

					p.mo.state = S_KART_FAST
				end
			end
		end
	end
	end
end)