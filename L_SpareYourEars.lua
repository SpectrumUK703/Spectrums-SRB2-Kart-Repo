local SRB2_StartSound = S_StartSound
local SRB2_StartSoundAtVolume = S_StartSoundAtVolume

rawset(_G, "S_StartSound", function(origin, soundnum, player)
	if origin and origin.valid and S_SoundPlaying(origin, soundnum)
		SRB2_StartSoundAtVolume(origin, soundnum, 85, player)
	else
		SRB2_StartSound(origin, soundnum, player)
	end
end)

rawset(_G, "S_StartSoundAtVolume", function(origin, soundnum, volume, player)
	if origin and origin.valid and S_SoundPlaying(origin, soundnum)
		SRB2_StartSoundAtVolume(origin, soundnum, volume/3, player)
	else
		SRB2_StartSoundAtVolume(origin, soundnum, volume, player)
	end
end)