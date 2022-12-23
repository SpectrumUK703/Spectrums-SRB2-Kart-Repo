--xItemLib compatibility layer for Battle Plus

--don't load shit if xItem isn't loaded
if not xItemLib then return end
--nor if battleplus isn't loaded
if not battleplus then return end

local xItemLib = xItemLib
local libfunc = xItemLib.func

local bpFramework = battleplus.framework
local emeraldthief = battleplus.emeraldthief
local itemrain = battleplus.itemrain
local mineblast = battleplus.mineblast
local hooliganroundup = battleplus.hooliganroundup

local BpCompatExt = {}

function BpCompatExt.preplayerthink(p, cmd)
    --print(p.xItemData.xItem_battleOdds)
end

function bpFramework.Main_ItemOdds(gamemode)
	if not (gamemode.itemodds or gamemode.itemoddsmodifier) then    -- no need for custom odds
        for p in players.iterate do
            if p.xItemData.xItem_battleOdds then    --but we do need to reset them
                resetOddsForItem(0, p)
            end
        end
        return 
    end
    if xItemLib.toggles.debugItem then return end	-- debug

    for p in players.iterate do
        --instead of rewriting the item system again 
        --let's trick battle plus into using xItem functions instead
        --TODO: something to allow custom items to show up in some game modes (eg. mine cannon in mine blast)
        for i = 1, #gamemode.itemodds do
            libfunc.setPlayerOddsForItem(i, p, nil, gamemode.itemodds[i])
        end
    end
end

local function rocketsneaker_pickupfunc(p, mcitem, mo)
	if battleplus.IsGamemode(BP_GM_EMERALDTHIEF) then -- emerald thief
        return not (emeraldthief.PlayerHasEmerald(mo.player))
    end
end

local function star_pickupfunc(p, mcitem, mo)
	if battleplus.IsGamemode(BP_GM_EMERALDTHIEF) then -- emerald thief
        return not (emeraldthief.PlayerHasEmerald(mo.player))
    end
end

local function mega_pickupfunc(p, mcitem, mo)
	if battleplus.IsGamemode(BP_GM_EMERALDTHIEF) then -- emerald thief
        return not (emeraldthief.PlayerHasEmerald(mo.player))
    end
end

local function boo_pickupfunc(p, mcitem, mo)
	if battleplus.IsGamemode(BP_GM_EMERALDTHIEF) then -- emerald thief
        return not (emeraldthief.PlayerHasEmerald(mo.player))
    end
end

function BpCompatExt.oddsfunc(newodds, pos, mashed, spbrush, p, secondist, pingame, pexiting, item)
    if server and server.bp_server and server.bp_server.gamemode then
        local gamemode = battleplus.gamemodes[server.bp_server.gamemode]
        if gamemode.itemoddsmodifier then
            return gamemode.itemoddsmodifier(p, item, newodds)
        end
    end
    return newodds
end

libfunc.setXItemModData("XITEM_BPCOMPAT", xItemLib.xItemNamespaces["KITEM_ROCKETSNEAKER"], 
    {
        pickupfunc = rocketsneaker_pickupfunc
    }
)

libfunc.setXItemModData("XITEM_BPCOMPAT", xItemLib.xItemNamespaces["KITEM_INVINCIBILITY"], 
    {
        pickupfunc = rocketsneaker_pickupfunc
    }
)

libfunc.setXItemModData("XITEM_BPCOMPAT", xItemLib.xItemNamespaces["KITEM_GROW"], 
    {
        pickupfunc = rocketsneaker_pickupfunc
    }
)

libfunc.setXItemModData("XITEM_BPCOMPAT", xItemLib.xItemNamespaces["KITEM_HYUDORO"], 
    {
        pickupfunc = rocketsneaker_pickupfunc
    }
)

-- remove floating items entirely in mine blast
addHook("MobjThinker", function(mcitem)
	-- just remove these in this gamemode
	if not (battleplus.IsGamemode(BP_GM_MINEBLAST)) then return end	-- not mine blast
	
	if (mcitem and mcitem.valid)
		P_RemoveMobj(mcitem)
		return
	end
end, MT_FLOATINGXITEM)

mineblast.HUDFunc_Mines = function(v, p)
    --make this only draw the bar using xitem functions

    local holding = (p.bp.mb_throwinfo and p.bp.mb_throwinfo.held)
	local maxstrength = (gamespeed == 0 and 58 or (gamespeed == 2 and 86 or 72))
	local strength = p.bp.mb_throwinfo and p.bp.mb_throwinfo.strength or 0

    --yup it's just that easy
    if holding then
        p.xItemData.xItem_timerBar = strength
        p.xItemData.xItem_maxTimerBar = maxstrength
    end
end



xItemLib.func.addXItemMod("XITEM_BPCOMPAT", "xItemLib Battle Plus Compatibility Layer", BpCompatExt)