local pd <const> = playdate
local sp <const> = pd.sound.sampleplayer.new
local fp <const> = pd.sound.fileplayer.new

local playedThisFrame = {}
local currentlyPlayingSong

AudioManager = {}
local audioManager <const> = AudioManager

AudioManager.sfx = {
    laserFire = sp("audio/laser"),             --https://freesound.org/people/Gemmellness/sounds/181356/
    crumble = sp("audio/crumble"),             --https://pixabay.com/sound-effects/rock-smash-6304/
    creatureSpawn = sp("audio/monster_spawn"), -- https://freesound.org/people/Xfrtrex/sounds/765631/
    creatureDeath = sp("audio/monster_die"),   -- https://freesound.org/people/Xfrtrex/sounds/765631/
    buildingPlace = sp("audio/building_place") -- https://freesound.org/people/AudioPapkin/sounds/755054/
}

local lowVol = 0.1
local medVol = 0.2
local highVol = 0.4
AudioManager.songs = {
    ambientSpace = fp("audio/space_ambient") --https://freesound.org/people/cliploop/sounds/750961/
}
AudioManager.songs.ambientSpace:setVolume(medVol)
AudioManager.volume = medVol

AudioManager.playSong = function(song)
    if song == currentlyPlayingSong then
        return
    end

    if currentlyPlayingSong then
        local previousSong = currentlyPlayingSong
        previousSong:setVolume(0, nil, 1.0, function()
            previousSong:stop()
        end)
    end

    currentlyPlayingSong = song
    AudioManager.updateMusicVol(CUR_MUSIC_VOL)
    song:play(0)
end

AudioManager.setMusicVolMenuOption = function()
    local menu = pd.getSystemMenu()
    menu:addOptionsMenuItem("Music", { "Off", "Low", "Med", "High" }, CUR_MUSIC_VOL, function(value)
        if currentlyPlayingSong then
            CUR_MUSIC_VOL = value
            AudioManager.updateMusicVol(value)
        end
    end)
end

AudioManager.updateMusicVol = function(value)
    local volume = 0.0
    if value == "Low" then
        volume = lowVol
    elseif value == "Med" then
        volume = medVol
    elseif value == "High" then
        volume = highVol
    end
    currentlyPlayingSong:setVolume(volume)
end

AudioManager.play = function(sound, count)
    if not sound or playedThisFrame[sound] then
        return
    end
    playedThisFrame[sound] = true
    local sample = sound:copy()
    if count then
        sample:play(count)
    else
        sample:play()
    end
    return sample
end

AudioManager.playRandom = function(sounds)
    local sound = sounds[math.random(#sounds)]
    audioManager.play(sound)
end

AudioManager.fadeOut = function(sound, time)
    time = time or 1000 -- ms
    local timer = pd.timer.new(time, 1.0, 0)
    timer.updateCallback = function()
        sound:setVolume(timer.value)
    end
    timer.timerEndedCallback = function()
        sound:stop()
    end
end

AudioManager.clearPlayedThisFrame = function()
    playedThisFrame = {}
end
