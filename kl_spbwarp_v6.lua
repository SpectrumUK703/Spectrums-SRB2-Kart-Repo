--a hacky edit of quantum jawz code by retrostation

rawset(_G, "spbwarptoggle" , CV_RegisterVar({
	name = "spbwarptoggle",
	defaultvalue = "On",
	flags = CV_NETVAR,
	PossibleValue = CV_OnOff
}))

local spbDist = 0
local warptimer = 0
local zip = 0
local offzet = 0
local warptimer = TICRATE/2
local function netvars(net)
    warptimer = net($)
	spbDist = net($)
	zip = net($)
	offzet = net($)
end
local function BlueShell(actor, mo)
	local addx = FixedMul(actor.momx, FRACUNIT/10)
	local addy = FixedMul(actor.momy, FRACUNIT/10)
	if spbwarptoggle.value
		if actor.tracer and actor.tracer.player

			--Shoutouts to SPB Attack math
			spbDist = (FixedDiv(FixedHypot(actor.tracer.player.mo.x - actor.x, actor.tracer.player.mo.y - actor.y) - actor.radius, actor.tracer.player.mo.scale)) / FRACUNIT
			//print("Distance from target:"..spbDist)
		
			//actor.floatspeed = 32*FRACUNIT
			if spbDist > 2000
				warptimer = max($-1, 0)
				//print("Time before warp:"..warptimer)
				actor.poof = nil
			end
		
			if warptimer == 0
			and actor.poof == nil
				actor.poof = true
				local zip = FixedMul(1500*FRACUNIT, actor.tracer.scale)
				local offzet = FixedMul(actor.tracer.height, actor.tracer.scale)
				P_TeleportMove(actor, actor.tracer.x-FixedMul(zip, cos(actor.tracer.angle)), actor.tracer.y-FixedMul(zip,sin(actor.tracer.angle)), actor.tracer.z+offzet)
			end
		end
		actor.colorized = true
		actor.color = SKINCOLOR_GREEN
	end
end
addHook("MobjThinker", BlueShell, MT_SPB)
addHook("NetVars", netvars)