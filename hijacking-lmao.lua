local CV_RegisterVar_vanilla = CV_RegisterVar

-- hijacking lmao
rawset(_G, "CV_RegisterVar", function(table)
	if table and table[1] == "tumbleignoreiframes"
		return CV_RegisterVar_vanilla({"_"..table[1], table[2], table[3], table[4], table[5]})
	end
	return CV_RegisterVar_vanilla(table)
end)

local FixedDiv_vanilla = FixedDiv

rawset(_G, "FixedDiv", function(x, y)
	return FixedDiv_vanilla(x, y or 1)
end)