COM_AddCommand("invertflightcontrols", function(p, arg1)
	p.invertflightcontrols = $ or 0
	if arg1 ~= nil
		if (tonumber(arg1) and tonumber(arg1) > 0) or arg1:lower() == "yes" or arg1:lower() == "on" or arg1:lower() == "true"
			p.invertflightcontrols = 1
		elseif (tonumber(arg1) ~= nil and tonumber(arg1) <= 0) or arg1:lower() == "no" or arg1:lower() == "off" or arg1:lower() == "false"
			p.invertflightcontrols = 0
		else
			p.invertflightcontrols = 1-$
		end
	else
		p.invertflightcontrols = 1-$
	end
	if p.invertflightcontrols == 1
		CONS_Printf(p, "Flight controls are now inverted.")
	else
		CONS_Printf(p, "Flight controls are now vanilla.")
	end
end)

addHook("PlayerCmd", function(p, cmd)
	if (p.rideroid or p.dlzrocket) and p.invertflightcontrols
		cmd.throwdir = -$
	end
end)