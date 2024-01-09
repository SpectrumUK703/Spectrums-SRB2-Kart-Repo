local FixedDiv_vanilla = FixedDiv

rawset("FixedDiv", function(x, y)
	return FixedDiv_vanilla(x, y or 1)
end)