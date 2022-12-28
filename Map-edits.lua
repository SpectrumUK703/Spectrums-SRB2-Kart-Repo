//Editing on mapload
addHook("MapLoad", function(mapnum)
	if mapnum == 10
		if sectors[161].floorheight > sectors[161].ceilingheight //FOF Error
			sectors[161].floorheight = sectors[161].ceilingheight - 32*FRACUNIT
		end
	elseif mapnum == 12 //Updating to match SRB2 Kart v1.6
		sectors[23].special = 7
		sectors[24].special = 7
		sectors[25].special = 7
	elseif mapnum == 573
		if lines[3912].special == 542
		and sectors[1132].special == 512
		and lines[3912].tag == sectors[1132].tag //Hadal Trench softlock
			sectors[1132].ceilingheight = -6432*FRACUNIT
		end
	end
end)