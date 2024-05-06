local function droptargetcontact(tmthing, thing)
	if not (tmthing and tmthing.valid and thing and thing.valid and tmthing.health and thing.health
	and tmthing.z + tmthing.height >= thing.z
	and tmthing.z <= thing.z + thing.height
	and thing.type == MT_PLAYER)
	or ((tmthing.target == thing or tmthing.target == thing.target) and tmthing.threshold)
	or (thing.player and (thing.player.hyudorotimer or thing.player.justbumped)) then
		return
	end
	thing.reducespeednexttic = true
end

addHook("MobjCollide", droptargetcontact, MT_DROPTARGET)
addHook("MobjMoveCollide", droptargetcontact, MT_DROPTARGET)
addHook("MobjCollide", droptargetcontact, MT_DROPTARGET_SHIELD)
addHook("MobjMoveCollide", droptargetcontact, MT_DROPTARGET_SHIELD)

addHook("MobjThinker", function(mo)
	if mo.reducespeednexttic
		mo.momx = $/2
		mo.momy = $/2
		mo.momz = $/2
		--print("speed reduced")
	end
	mo.reducespeednexttic = nil
end, MT_PLAYER)