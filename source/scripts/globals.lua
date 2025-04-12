local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities

FONT = gfx.font.new("fonts/Sasser Slab/Sasser-Slab")


TAGS = {
    building = 1,
    laser = 2,
    enemy = 3,
    creature = 4
}

Z_INDEXES = {
    moon = 0,
    building = 10,
    enemy = 30,
    creature = 30,
    laser = 50,
    cursor = 100
}

CUR_MUSIC_VOL = "High"

-- DEBUG
local debugMode = false
DRAW_FPS = debugMode

-- Save Data
HIGH_SCORES = {}
HIGHEST_BUILDING_COUNT = 0
TOTAL_BUILDINGS_PLACED = 0
LASERS_SHOT = 0
ENEMIES_KILLED = 0

local function loadGameData()
    local gameData = pd.datastore.read()
    if gameData then
        HIGH_SCORES = gameData.highScores or HIGH_SCORES
        HIGHEST_BUILDING_COUNT = gameData.highestBuildingCount or HIGHEST_BUILDING_COUNT
        TOTAL_BUILDINGS_PLACED = gameData.totalBuildingsPlaced or TOTAL_BUILDINGS_PLACED
        LASERS_SHOT = gameData.lasersShot or LASERS_SHOT
        ENEMIES_KILLED = gameData.enemiesKilled or ENEMIES_KILLED
    end
end

loadGameData()

function SAVE_GAME_DATA()
    local gameData = {
        highScores = HIGH_SCORES,
        highestBuildingCount = HIGHEST_BUILDING_COUNT,
        totalBuildingsPlaced = TOTAL_BUILDINGS_PLACED,
        lasersShot = LASERS_SHOT,
        enemiesKilled = ENEMIES_KILLED
    }

    pd.datastore.write(gameData)
end

--Core
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/animation"
import "CoreLibs/animator"

-- Audio
import "scripts/audio/audioManager"

-- Libraries
import "scripts/libraries/Assets"
import "scripts/libraries/Utilities"
import "scripts/libraries/SceneManager"

--Game Scenes
import "scripts/game/gameScene"

--Moon
import "scripts/moon/moon"

--Cursor
import "scripts/cursors/cursor"

-- Buildings
import "scripts/buildings/buildingManager"
import "scripts/buildings/building"

-- Enemies
import "scripts/enemies/enemyManager"
import "scripts/enemies/enemy"
import "scripts/enemies/creature"

-- Lasers
import "scripts/weapons/weaponManager"
import "scripts/weapons/laser"

-- Scenes
import "scripts/title/titleScene"
import "scripts/title/instructionsScene"
import "scripts/title/gameOverScene"
