-- aj@worldsbe.st
-- "FIRMSNEAKER" - boosts sneaker items to 50% speedboost, even on hard, while not affecting dash panels
-- let's move this out of server repacks since file limit is a billion now.

addHook("ThinkFrame", do
  for p in players.iterate
    if p.spectator continue end
    if not p.mo.valid then continue end
    if p.FSlastframeitem ~= nil then
      if p.kartstuff[k_sneakertimer] > p.FSlastframetimer then
        if p.FSlastframeitem == KITEM_SNEAKER and p.kartstuff[k_itemtype] ~= KITEM_SNEAKER then
          p.FSdohardsneaker = true
        elseif p.kartstuff[k_itemtype] == KITEM_SNEAKER and p.kartstuff[k_itemamount] < p.FSlastframeamount then
          p.FSdohardsneaker = true
		elseif p.kartstuff[k_rocketsneakertimer] and p.FSlastframebutton == 0 and (p.cmd.buttons & BT_ATTACK) then
		  p.FSdohardsneaker = true
        else
          p.FSdohardsneaker = false
        end
      end
    end
	if p.FSdohardsneaker and p.kartstuff[k_sneakertimer] then
        p.kartstuff[k_speedboost] = max($, FRACUNIT/2)
        p.FSfirmbonus = p.kartstuff[k_sneakertimer]
    elseif p.FSfirmbonus and p.kartstuff[k_sneakertimer] then
        p.kartstuff[k_speedboost] = max($, FRACUNIT/2)
    end
    p.FSfirmbonus = $ or 0
    p.FSfirmbonus = max(0, $-1)
    p.FSlastframeitem = p.kartstuff[k_itemtype]
    p.FSlastframeamount = p.kartstuff[k_itemamount]
    p.FSlastframetimer = p.kartstuff[k_sneakertimer]
	if p.FSlastframebutton == nil then p.FSlastframebutton = 0 end
	p.FSlastframebutton = (p.cmd.buttons & BT_ATTACK) and ($+1) or 0
    p.FSdohardsneaker = p.FSdohardsneaker or false
  end
end)

--hud.add(function(v, p, c)
--    if p.FSlastframeitem == nil then return end
--    v.drawString(0, 0, "SPEEDBOOST: "..p.kartstuff[k_speedboost])
--    v.drawString(0, 10, "SNEAKER TIMER: "..p.kartstuff[k_sneakertimer])
--    v.drawString(0, 20, "FIRMBONUS: "..p.FSfirmbonus)
--end)