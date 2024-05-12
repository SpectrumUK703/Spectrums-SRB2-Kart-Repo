addHook("PlayerThink", function(player)
  if player.lives < 10
    player.lives = 10
  end
end)
