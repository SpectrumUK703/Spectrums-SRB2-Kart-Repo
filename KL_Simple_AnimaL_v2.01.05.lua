---------------------------
-- Simple AnimaL 2.01.05 --
---------------------------

-- i think there was this whole thing about turning globals into locals making Lua faster?
local A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P = A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P -- driving frames
local Q, R, S = Q, R, S                                                                               -- attacked, squished, signpost
local T, U, V, W, X, Y, Z = T, U, V, W, X, Y, Z                                                       -- mod frames. for frames after Z,
                                                                                                      -- use numbers (starting with 26.)
local CURRENT_VERSION = 020105
local ANIMATION_DEFINITIONS = {}
local ANIMATION_HELPERS = {}
local SEQUENCE_HOOKS = {}

-- This script is Reusable content by Togen. As part of its functions, it allows newer versions of the script to overwrite its functions.
-- Send me a message if you think somebody's got a weird hack that is doing bad things to other Simple AnimaLs, and I'll shoot them dead.

-- Base sequences:
--  drift
--    drift_left
--    drift_right
--  goal
--  pain
--  run
--    run_left
--    run_right
--  spin
--  squish
--  stand
--    stand_left
--    stand_right
--  trick
--    trick_left
--    trick_right
--  walk
--    walk_left
--    walk_right

-- For anything else more complex, like checking if the player is airborne or underwater, create a sequence hook. All sequence hooks will
-- be looped through, and the first result that returns a non-nil value will be used as the sequence value. Simple_AnimaL will handle the
-- actual animation itself.

function ANIMATION_HELPERS.getPlayer(mobj)
  if mobj.player -- the actual player
    return mobj.player
  elseif mobj.target.player -- the target's player for overlays and stuff.
    return mobj.target.player
  elseif mobj.target.target.player -- :weary:
    return mobj.target.target.player
  end
end

function ANIMATION_HELPERS.getSkin(mobj)
  if mobj.skin -- the actual skin
    return mobj.skin
  elseif mobj.target.skin -- the target's skin for secondcolor signpost overlays and stuff.
    return mobj.target.skin
  elseif mobj.target.target.skin --  just in case.
    return mobj.target.target.skin
  end
end

function ANIMATION_HELPERS.isCountdown(mobj) -- Checks if we can start working on a start boost.
  return (leveltime >= starttime-(2*TICRATE) and leveltime <= starttime)
end

function ANIMATION_HELPERS.isCountdownCharging(mobj) -- Checks if we have any kind of acceleration input during the start.
  return ANIMATION_HELPERS.getPlayer(mobj).kartstuff[k_boostcharge] > 0
end

function ANIMATION_HELPERS.isMovingForward(mobj) -- Checks if the player is moving forward (conveyors, etc. ignored.)
  local player = ANIMATION_HELPERS.getPlayer(mobj)
  local mymovangle = R_PointToAngle2(0, 0, player.rmomx, player.rmomy)
  local anglediff = (AngleFixed(mymovangle - mobj.angle)/FRACUNIT) % 360
  return (player.speed > 0 and not (anglediff > 90 and anglediff < 270))
end

function ANIMATION_HELPERS.isMovingBackward(mobj) -- Checks if the player is moving backward (conveyors, etc. ignored.)
  local player = ANIMATION_HELPERS.getPlayer(mobj)
  local mymovangle = R_PointToAngle2(0, 0, player.rmomx, player.rmomy)
  local anglediff = (AngleFixed(mymovangle - mobj.angle)/FRACUNIT) % 360
  return (player.speed > 0 and anglediff > 90 and anglediff < 270)
end

function ANIMATION_HELPERS.isTurningLeft(mobj) -- Checks if the player is turning left.
  return ANIMATION_HELPERS.getPlayer(mobj).cmd.driftturn > 0
end

function ANIMATION_HELPERS.isTurningRight(mobj) -- Checks if the player is turning right.
  return ANIMATION_HELPERS.getPlayer(mobj).cmd.driftturn < 0
end

function ANIMATION_HELPERS.isDriftingLeft(mobj) -- Checks if the player is drifting right. Current turning input ignored.
  return ANIMATION_HELPERS.getPlayer(mobj).kartstuff[k_drift] > 0
end

function ANIMATION_HELPERS.isDriftingRight(mobj) -- Checks if the player is drifting right. Current turning input ignored.
  return ANIMATION_HELPERS.getPlayer(mobj).kartstuff[k_drift] < 0
end

function ANIMATION_HELPERS.isPained(mobj) -- Checks if the player is pained (dying, failed a trick.)
  return ((mobj.health <= 0) or (ANIMATION_HELPERS.getPlayer(mobj).trickstun))
end

function ANIMATION_HELPERS.isSquished(mobj) -- Checks if the player is squished.
  return ANIMATION_HELPERS.getPlayer(mobj).kartstuff[k_squishedtimer] > 0
end

function ANIMATION_HELPERS.isSpinning(mobj) -- Checks if the player is spinning.
  local player = ANIMATION_HELPERS.getPlayer(mobj)
  return ((player.kartstuff[k_spinouttimer] > 0) or (player.powers[pw_nocontrol] and player.pflags & PF_SKIDDOWN) or player.pflags & PF_SLIDING)
end

function ANIMATION_HELPERS.isTricking(mobj) -- Checks if the player is tricking.
  local player = ANIMATION_HELPERS.getPlayer(mobj)
  return (player.trickactive or (player.hastricked and player.spintimer)) and not(G_BattleGametype())
end

function ANIMATION_HELPERS.isRunSpeed(mobj) -- Checks if the player is at running speed.
  return ANIMATION_HELPERS.getPlayer(mobj).speed > mobj.scale * 20
end

function ANIMATION_HELPERS.isWalkSpeed(mobj) -- Checks if the player is at walking speed, but not running speed.
  local player = ANIMATION_HELPERS.getPlayer(mobj)
  return player.speed > 0 and player.speed <= mobj.scale * 20
end

function ANIMATION_HELPERS.isWalkSpeedMultiplied(mobj, fixed_multiplier) -- Checks if the player's speed is >= their walking speed multiplied (using fixed-point math.)
  local run = (mobj.scale * 20)
  return ANIMATION_HELPERS.getPlayer(mobj).speed >= FixedMul(run, fixed_multiplier)
end

function ANIMATION_HELPERS.isNoSpeed(mobj) -- Checks if the player lacks innate speed (conveyors, etc. ignored.)
  return ANIMATION_HELPERS.getPlayer(mobj).speed == 0
end

function ANIMATION_HELPERS.isUnderwater(mobj) -- Checks if the player is underwater.
  return mobj.eflags & MFE_UNDERWATER
end

function ANIMATION_HELPERS.isAirborne(mobj) -- Checks if the player is airborne.
  return not P_IsObjectOnGround(mobj)
end

function ANIMATION_HELPERS.isAscending(mobj) -- Checks if the player is rising through the air.
  return mobj.momz > 0 and not P_IsObjectOnGround(mobj)
end

function ANIMATION_HELPERS.isDescending(mobj) -- Checks if the player is falling through the air.
  return mobj.momz < 0 and not P_IsObjectOnGround(mobj)
end

function ANIMATION_HELPERS.isRespawning(mobj) -- Checks if the player is respawning.
  return ANIMATION_HELPERS.getPlayer(mobj).kartstuff[k_respawn] > 0
end

function ANIMATION_HELPERS.isDropDashing(mobj) -- Checks if the player is charging a drop dash.
  return ANIMATION_HELPERS.getPlayer(mobj).kartstuff[k_dropdash] > 0
end

function ANIMATION_HELPERS.isHyudoro(mobj) -- Checks if the player is ghostly.
  return ANIMATION_HELPERS.getPlayer(mobj).kartstuff[k_hyudorotimer] > 0
end

function ANIMATION_HELPERS.isGrow(mobj) -- Checks if the player is grown.
  return ANIMATION_HELPERS.getPlayer(mobj).kartstuff[k_growshrinktimer] > 0 or (HugeQuest and p.huge > 0)
end

function ANIMATION_HELPERS.isShrink(mobj) -- Checks if the player is shrunk.
  return ANIMATION_HELPERS.getPlayer(mobj).kartstuff[k_growshrinktimer] < 0
end

function ANIMATION_HELPERS.isInvincible(mobj) -- Checks if the player is using an Invincibility item.
  return ANIMATION_HELPERS.getPlayer(mobj).kartstuff[k_invincibilitytimer] > 0
end

function ANIMATION_HELPERS.isSpringing(mobj) -- Checks if the player has bounced off of a map spring or used a Pogo Spring item.
  return ANIMATION_HELPERS.getPlayer(mobj).kartstuff[k_pogospring] > 0
end

function ANIMATION_HELPERS.isGoalOverlay(mobj) -- Checks if the mobj is a goalpost overlay that we can overwrite.
  return mobj.type == MT_OVERLAY and (mobj.state == S_PLAY_SIGN) and _G["SIMPLE_ANIMAL_DEFINITIONS"][ANIMATION_HELPERS.getSkin(mobj)]
end

function ANIMATION_HELPERS.isGoalOverlaySecondcolor(mobj) -- Checks if the mobj is a goalpost overlay that we can overwrite.
  return mobj.type == MT_OVERLAY and (mobj.sprite ~= SPR_PLAY) and ANIMATION_HELPERS.isGoalOverlay(mobj.target)
end

function ANIMATION_HELPERS.isChainChomp(mobj) -- Checks if the player is riding a Chain Chomp (RollTheDice).
  return ANIMATION_HELPERS.getPlayer(mobj).chomptimer > 0
end

function ANIMATION_HELPERS.isFinished(mobj) -- Checks if the player has finished the level.
  return ANIMATION_HELPERS.getPlayer(mobj).exiting
end

-- Helpers end here.





local function this_Simple_AnimaL_thinker(mobj)
  local use_sequence = _G["SIMPLE_ANIMAL_CHANGER"]

  if not (mobj and mobj.valid)
    return
  elseif mobj.type == MT_PLAYER and not _G["SIMPLE_ANIMAL_DEFINITIONS"][mobj.skin] and mobj.sprite == SPR_UNKN then -- panic button to fix a hardcode bug.
    -- this won't fire if all of the players are AnimaLs, it makes for better testing that way.
    -- print("[Simple AnimaL] Panic button activated; a non-AnimaL skin tried to use nonexistent frames.")
    local vanilla_frames = {[S_KART_STND1] = A, [S_KART_STND2] = B, [S_KART_STND1_L] = C, [S_KART_STND2_L] = D, [S_KART_STND1_R] = E, [S_KART_STND2_R] = F,
                            [S_KART_WALK1] = J, [S_KART_WALK2] = G, [S_KART_WALK1_L] = K, [S_KART_WALK2_L] = H, [S_KART_WALK1_R] = L, [S_KART_WALK2_R] = I,
                            [S_KART_RUN1] = A, [S_KART_RUN2] = J, [S_KART_RUN1_L] = C, [S_KART_RUN2_L] = K, [S_KART_RUN1_R] = E, [S_KART_RUN2_R] = L,
                            [S_KART_DRIFT1_L] = M, [S_KART_DRIFT2_L] = N, [S_KART_DRIFT1_R] = O, [S_KART_DRIFT2_R] = P,
                            [S_KART_SPIN] = Q, [S_KART_PAIN] = Q, [S_KART_SQUISH] = R}
    for i=S_KART_STND1,S_KART_SQUISH do
      states[i].sprite, states[i].frame = SPR_PLAY, vanilla_frames[i]
    end
    states[S_PLAY_SIGN].sprite, states[S_PLAY_SIGN].frame = SPR_PLAY, S
    mobj.state = S_KART_STND1 -- hide the UNKN sprite this tic.
  elseif mobj.type == MT_PLAYER and _G["SIMPLE_ANIMAL_DEFINITIONS"][mobj.skin] then
    local helpers = _G["SIMPLE_ANIMAL_HELPERS"]
    
    if not helpers
      return
    elseif helpers.isSquished(mobj)
      use_sequence(mobj, {"squish", "pain", "spin", "stand"})
    elseif helpers.isSpinning(mobj)
      use_sequence(mobj, {"spin", "stand"})
    elseif helpers.isPained(mobj)
      use_sequence(mobj, {"pain", "spin", "stand"})
    elseif helpers.isTricking(mobj) -- Acrobatics. Acrobasics doesn't use trick frames, but this way is much cooler so it stays.
      if helpers.isTurningRight(mobj)
        use_sequence(mobj, {"trick_right", "trick", "drift_right", "drift", "walk_right", "walk", "stand_right", "stand"})
      else
        use_sequence(mobj, {"trick_left", "trick", "drift_left", "drift", "walk_left", "walk", "stand_left", "stand"})
      end      
    elseif helpers.isNoSpeed(mobj)
      if helpers.isTurningRight(mobj)
        use_sequence(mobj, {"stand_right", "stand"})
      elseif helpers.isTurningLeft(mobj)
        use_sequence(mobj, {"stand_left", "stand"})
      else
        use_sequence(mobj, {"stand"})
      end
    elseif helpers.isDriftingLeft(mobj) and not helpers.isAirborne(mobj)
      use_sequence(mobj, {"drift_left", "drift", "walk_left", "walk", "stand_left", "stand"})
    elseif helpers.isDriftingRight(mobj) and not helpers.isAirborne(mobj)
      use_sequence(mobj, {"drift_right", "drift", "walk_right", "walk", "stand_right", "stand"})
    elseif helpers.isRunSpeed(mobj)
      if helpers.isTurningRight(mobj)
        use_sequence(mobj, {"run_right", "run", "walk_right", "walk", "stand_right", "stand"})
      elseif helpers.isTurningLeft(mobj)
        use_sequence(mobj, {"run_left", "run", "walk_left", "walk", "stand_left", "stand"})
      else
        use_sequence(mobj, {"run", "walk", "stand"})
      end
    elseif helpers.isWalkSpeed(mobj)
      if helpers.isTurningRight(mobj)
        use_sequence(mobj, {"walk_right", "walk", "stand_right", "stand"})
      elseif helpers.isTurningLeft(mobj)
        use_sequence(mobj, {"walk_left", "walk", "stand_left", "stand"})
      else
        use_sequence(mobj, {"walk", "stand"})
      end
    end
  elseif _G["SIMPLE_ANIMAL_HELPERS"].isGoalOverlay(mobj) or _G["SIMPLE_ANIMAL_HELPERS"].isGoalOverlaySecondcolor(mobj) then
    use_sequence(mobj, {"goal"})
  
  mobj.eflags = (mobj.eflags & ~MFE_VERTICALFLIP) | (mobj.target.eflags & MFE_VERTICALFLIP) -- calculate vertical offset/flipping
  mobj.destscale = mobj.target.scale
  mobj.scale = mobj.destscale
  mobj.angle = mobj.target.angle
  
  local zoffs = FixedMul((states[mobj.state].var2)*FRACUNIT, mobj.scale)
  local zdest = mobj.target.z + zoffs
  if (mobj.eflags & MFE_VERTICALFLIP)
      zdest = (mobj.target.z + mobj.target.height - mobj.height) - zoffs
  end
  P_MoveOrigin(mobj, mobj.target.x, mobj.target.y, zdest) -- teleport to signpost.
  return true -- interrupt the normal thinker, it messes with our animation.
  end
end

local function this_Simple_AnimaL_use_sequence(mobj, sequences)
  local skin = ANIMATION_HELPERS.getSkin(mobj)
  local last_sequence = mobj.Simple_AnimaL_sequence_last
  
  if not _G["SIMPLE_ANIMAL_DEFINITIONS"][skin]
    return
  end
  
  local validated_sequence
  for key, hook in pairs(_G["SIMPLE_ANIMAL_HOOKS"])
    local result = hook(mobj, sequences)
    if result ~= nil
      validated_sequence = result
      break
    end
  end
  for key, sequence in pairs(sequences)
    if _G["SIMPLE_ANIMAL_DEFINITIONS"][skin][sequence] and validated_sequence == nil
      validated_sequence = sequence
      break
    end
  end

  local validated_sequence_table = _G["SIMPLE_ANIMAL_DEFINITIONS"][skin][validated_sequence]
  local validated_duration = #validated_sequence_table
  
  if (mobj.Simple_AnimaL_timer == nil) or (validated_sequence ~= last_sequence)
    mobj.Simple_AnimaL_timer = 1
    mobj.Simple_AnimaL_sequence_last = validated_sequence
  elseif (validated_duration > 1) and (mobj.Simple_AnimaL_timer < validated_duration)
    mobj.Simple_AnimaL_timer = ($ + 1)
  else
    mobj.Simple_AnimaL_timer = 1
  end

  local timer = max(1,mobj.Simple_AnimaL_timer)
  mobj.frame = validated_sequence_table[timer]
end

local function this_Simple_AnimaL_debug()
  print("Simple AnimaL versions: " + table.concat(SIMPLE_ANIMAL_ALL_VERSIONS, ", "))
  local keys = {}
  
  for k, v in pairs(SIMPLE_ANIMAL_DEFINITIONS) do
    table.insert(keys, k)
  end
  
  print("Simple AnimaL definitions: " + table.concat(keys, ", "))
end




local last_version = nil
if not (_G["SIMPLE_ANIMAL_VERSION"]) then
  -- Step 1: Check if this is the first Simple AnimaL instance.
  rawset(_G, "SIMPLE_ANIMAL_VERSION", CURRENT_VERSION)
  rawset(_G, "SIMPLE_ANIMAL_ALL_VERSIONS", {CURRENT_VERSION})
  rawset(_G, "SIMPLE_ANIMAL_THINKER", this_Simple_AnimaL_thinker)
  rawset(_G, "SIMPLE_ANIMAL_CHANGER", this_Simple_AnimaL_use_sequence)
  
  rawset(_G, "SIMPLE_ANIMAL_DEFINITIONS", {}) -- tables with animation data
  rawset(_G, "SIMPLE_ANIMAL_HELPERS", {}) -- helper functions
  rawset(_G, "SIMPLE_ANIMAL_HOOKS", {}) -- creator-made hooks
    
elseif (_G["SIMPLE_ANIMAL_VERSION"] < CURRENT_VERSION) then
  last_version = _G["SIMPLE_ANIMAL_VERSION"]
  print("[Simple AnimaL] Running an update.")
  if(_G["SIMPLE_ANIMAL_VERSION"] < 10100) -- helpers introduced in 1.01.00
    rawset(_G, "SIMPLE_ANIMAL_HELPERS", {})
  end
  if(_G["SIMPLE_ANIMAL_VERSION"] < 20000)
    rawset(_G, "SIMPLE_ANIMAL_ALL_VERSIONS", {SIMPLE_ANIMAL_VERSION}) -- debug/version tracking introduced in 2.00.00, track previous version number
  end
  
  -- Step 2: Check if we can update other instances.
  table.insert(SIMPLE_ANIMAL_ALL_VERSIONS, CURRENT_VERSION)
  rawset(_G, "SIMPLE_ANIMAL_VERSION", CURRENT_VERSION)
  rawset(_G, "SIMPLE_ANIMAL_THINKER", this_Simple_AnimaL_thinker)
  rawset(_G, "SIMPLE_ANIMAL_CHANGER", this_Simple_AnimaL_use_sequence)
end

if not SIMPLE_ANIMAL_HARDHOOKS -- Do really weird hooking to guarantee that Simple AnimaL takes priority over everything else.
  local this_player_version = 2
  local this_overlay_version = 1
  rawset(_G, "SIMPLE_ANIMAL_HARDHOOKS", {})
  addHook("PostThinkFrame", function()
    local loadpriority = 1 -- Change this value if you must, I have already won.
    if (leveltime >= loadpriority) then
      if (not SIMPLE_ANIMAL_HARDHOOKS.player) then 
        addHook("PostThinkFrame", function(mo)
        if SIMPLE_ANIMAL_HARDHOOKS.player > this_player_version then return end
        for player in players.iterate do
          if not (player.valid and player.mo) then continue end
          SIMPLE_ANIMAL_THINKER(player.mo)
          if (player.mo.ksc_overlay and player.mo.ksc_overlay.valid)
            player.mo.ksc_overlay.frame = player.mo.frame -- secondcolor hack
          end
          if (player.rainbowcolor and player.rainbowcolor.valid)
            player.rainbowcolor.frame = player.mo.frame -- dynaskins hack
          end
        end
      end)
      
      SIMPLE_ANIMAL_HARDHOOKS.player = this_player_version
      end
    
    if (not SIMPLE_ANIMAL_HARDHOOKS.overlay) then 
      addHook("MobjThinker", function(mo)
        if SIMPLE_ANIMAL_HARDHOOKS.overlay > this_overlay_version then return end
        return SIMPLE_ANIMAL_THINKER(mo)
      end, MT_OVERLAY)
      SIMPLE_ANIMAL_HARDHOOKS.overlay = this_overlay_version
      end
    end
  end
  )
end





if not SIMPLE_ANIMAL_DEBUG_FUNC -- Add this console command for some testing purposes.
  rawset(_G, "SIMPLE_ANIMAL_DEBUG_FUNC", this_Simple_AnimaL_debug)
  COM_AddCommand("simple_animal", function()
    SIMPLE_ANIMAL_DEBUG_FUNC()
  end, COM_LOCAL)
end





-- Get defintions and hooks from this instance, add them to the global variables.
for def, value in pairs(ANIMATION_DEFINITIONS)
  SIMPLE_ANIMAL_DEFINITIONS[def] = value
end
for key, helper in pairs(ANIMATION_HELPERS)
  if not SIMPLE_ANIMAL_HELPERS[key]
    SIMPLE_ANIMAL_HELPERS[key] = helper
  end
end
for key, hook in pairs(SEQUENCE_HOOKS)
  table.insert(SIMPLE_ANIMAL_HOOKS, hook)
end