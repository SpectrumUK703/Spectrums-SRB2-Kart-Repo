local k_itemtype = k_itemtype
local k_growshrinktimer = k_growshrinktimer
local k_invincibilitytimer = k_invincibilitytimer
local k_itemamount = k_itemamount
local KITEM_INVINCIBILITY = KITEM_INVINCIBILITY
local KITEM_GROW = KITEM_GROW
local TICRATE = TICRATE
local MT_INVULNFLASH = MT_INVULNFLASH
local pw_flashing = pw_flashing
local k_squishedtimer = k_squishedtimer
local k_spinouttimer = k_spinouttimer
local k_hyudorotimer = k_hyudorotimer
local k_bumper = k_bumper
local k_comebacktimer = k_comebacktimer
local k_comebackmode = k_comebackmode
local sfx_alarmg = sfx_alarmg
local sfx_kgrow = sfx_kgrow
local sfx_alarmi = sfx_alarmi
local sfx_kinvnc = sfx_kinvnc
local cv_kartdebugshrink = CV_FindVar("kartdebugshrink")
local cv_kartinvinsfx = CV_FindVar("kartinvinsfx")
local itemtime = 8*TICRATE
local invinctime = itemtime+(2*TICRATE)
local growtime = itemtime+(4*TICRATE)

local G_BattleGametype = G_BattleGametype
local CV_FindVar = CV_FindVar
local P_SpawnMobj = P_SpawnMobj
local P_SetScale = P_SetScale
local P_RestoreMusic = P_RestoreMusic
local S_StartSound = S_StartSound
local K_PlayPowerGloatSound = K_PlayPowerGloatSound
local K_DoInstashield = K_DoInstashield

local function P_IsLocalPlayer(p)
	return (p == consoleplayer or p == secondarydisplayplayer or p == thirddisplayplayer or p == fourthdisplayplayer)
end

--Copied from HugeQuest
--Thanks Callmore
local function shouldHurt(p)
	return not (p.powers[pw_flashing] > 0 or p.kartstuff[k_squishedtimer] > 0 or p.kartstuff[k_spinouttimer] > 0
		or p.kartstuff[k_invincibilitytimer] > 0 or p.kartstuff[k_growshrinktimer] > 0 or p.kartstuff[k_hyudorotimer] > 0 or (HugeQuest and p.hugequest.huge > 0)
		or (G_BattleGametype() and ((p.kartstuff[k_bumper] <= 0 and p.kartstuff[k_comebacktimer]) or p.kartstuff[k_comebackmode] == 1)))
end

local mercy_item = CV_RegisterVar({
	name = "mercy_item",
	defaultvalue = "On",
	flags = CV_NETVAR,
	possiblevalue = CV_OnOff
})

local function activate(p)
	if not mercy_item.value then return end
	cv_kartdebugshrink = $ or CV_FindVar("kartdebugshrink")
	cv_kartinvinsfx = $ or CV_FindVar("kartinvinsfx")
	local mo = p.mo
	if not (mo and mo.valid) then return end
	if not shouldHurt(p) then return end
	local ks = p.kartstuff
	local itemtype = ks[k_itemtype]
	if itemtype == KITEM_INVINCIBILITY
		local overlay = P_SpawnMobj(mo.x, mo.y, mo.z, MT_INVULNFLASH)
		overlay.target = mo
		overlay.destscale = mo.scale
		P_SetScale(overlay, mo.scale)
		ks[k_invincibilitytimer] = invinctime // 10 seconds
		P_RestoreMusic(p)
		if (not P_IsLocalPlayer(p))
			S_StartSound(mo, (cv_kartinvinsfx.value and sfx_alarmi or sfx_kinvnc))
		end
		K_PlayPowerGloatSound(mo)
		ks[k_itemamount] = $ and $-1 or 0
		return false
	elseif itemtype == KITEM_GROW
		if ks[k_growshrinktimer] < 0
			return --nah
		else
			K_PlayPowerGloatSound(mo)
			mo.scalespeed = mapobjectscale/TICRATE
			mo.destscale = (3*mapobjectscale)/2
			if (cv_kartdebugshrink.value and not modeattacking and not p.bot)
				mo.destscale = (6*mo.destscale)/8
			end
			ks[k_growshrinktimer] = growtime // 12 seconds
			P_RestoreMusic(p)
			if (not P_IsLocalPlayer(p))
				S_StartSound(mo, (cv_kartinvinsfx.value and sfx_alarmg or sfx_kgrow))
			end
			S_StartSound(mo, sfx_kc5a)
		end
		ks[k_itemamount] = $ and $-1 or 0
		return false
	end
end

local function shouldactivate(p)
	if activate(p) == false
		K_DoInstashield(p)
		return false
	end
end

addHook("ShouldSquish", shouldactivate)
addHook("ShouldExplode", shouldactivate)
addHook("ShouldSpin", shouldactivate)

addHook("TouchSpecial", function(mo, mo2)
	if mo2.player
		return (activate(mo2.player) == false)
	end
end, MT_EGGMANITEM)

local hostmodload

addHook("ThinkFrame", function()
	if hostmodload or not (server and HOSTMOD and leveltime > TICRATE) then return end
	HM_Scoreboard_AddMod({disp = "Mercy Item", var = "mercy_item"})
	hostmodload = true
end)