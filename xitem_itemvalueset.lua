local function booleanconvert(boolstring)
	if type(boolstring) ~= "string" then return end
	if string.lower(boolstring) == "true" or string.lower(boolstring) == "on" or string.lower(boolstring) == "1"
		return true
	elseif string.lower(boolstring) == "false" or string.lower(boolstring) == "off" or string.lower(boolstring) == "0"
		return false
	end
end

local function setItem(p, cv, boolstring)
	local i = tonumber(cv)
	local t
	local bool = booleanconvert(boolstring)
	if not i then
		i = tostring(cv)
		t = xItemLib.func.findItemByFriendlyName(i, true)
		if t then
			if #t == 1 then
				if bool ~= nil
					xItemLib.toggles.xItemToggles[t[1]] = bool
				else
					xItemLib.toggles.xItemToggles[t[1]] = (not $)
				end
				xItemLib.toggles.allToggle = true
				print("\x82"..xItemLib.xItemData[t[1]].name.."\x80 is now "..(xItemLib.toggles.xItemToggles[t[1]] and "enabled" or "disabled"))
				return
			else
				table.sort(t)
				local s = ""
				CONS_Printf(p, "Found too many items! Did you mean:")
				for x, it in ipairs(t) do
					s = $..(xItemLib.xItemData[it].name.." (ID \x82".. it.."\x80)")
					if x ~= #t then
						s = $..", \n"
					end
				end
				CONS_Printf(p, s)
				
				s = nil
				return
			end
		end
		--then by internal
		t = xItemLib.func.findItemByNamespace(i, true)
		if t > 0 then
			if bool ~= nil
				xItemLib.toggles.xItemToggles[t] = bool
			else
				xItemLib.toggles.xItemToggles[t] = (not $)
			end
			xItemLib.toggles.allToggle = true
			print("\x82"..xItemLib.xItemData[t].name.."\x80 is now "..(xItemLib.toggles.xItemToggles[t] and "enabled" or "disabled"))
			return
		end
	end
	--then just vanilla kart behaviour (or all items if no argument)
	i = max(min(tonumber(i) or 0, xItemLib.func.countItems()), 0)
	if i > 0 then
		if bool ~= nil
			xItemLib.toggles.xItemToggles[i] = bool
		else
			xItemLib.toggles.xItemToggles[i] = (not $)
		end
		xItemLib.toggles.allToggle = true
		print("\x82"..xItemLib.xItemData[i].name.."\x80 is now "..(xItemLib.toggles.xItemToggles[i] and "enabled" or "disabled"))
	else
		if bool ~= nil
			xItemLib.toggles.allToggle = bool
		else
			xItemLib.toggles.allToggle = (not $)
		end
		for i = 1, xItemLib.func.countItems() do
			xItemLib.toggles.xItemToggles[i] = xItemLib.toggles.allToggle
		end
		print("Toggled all xItems to " .. (xItemLib.toggles.allToggle and "enabled (".."\x82".."all items".."\x80".." can appear)" or "disabled (only ".."\x82".."the first loaded item".."\x80".." will appear)"))
	end
	
	t = nil
	i = nil
end

COM_AddCommand("setxitem", setItem, 1) --sets specified items, or all if none specified