-- Importing libraries used for drawCircleAtPoint and crankIndicator
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/animation"
import "libraries/Assets"

-- Localizing commonly used globals
local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets

-- Preload Images
assets.preloadImages({ "images/stars" })
assets.preloadImagetable("images/moon-table-512-512.png")

-- Setup
pd.display.setRefreshRate(30)
local sasserFont = gfx.font.new("fonts/Sasser Slab/Sasser-Slab")
gfx.setImageDrawMode(gfx.kDrawModeNXOR)
gfx.setFont(sasserFont)

--Game State
local score = 0

--Background
local starsImage = assets.getImage("images/stars")
local starsSprite = gfx.sprite.new(starsImage)
starsSprite:setIgnoresDrawOffset(true)
starsSprite:moveTo(200, 120)
starsSprite:add()

--Moons
local moonSriteTable = assets.getImagetable("images/moon.png")
local moonFrameCount = 113
local currentFrame = 1
local moonSprite = gfx.sprite.new(moonSriteTable[currentFrame])
moonSprite:moveTo(200, 340)
moonSprite:add()

-- playdate.update function is required in every project!
function playdate.update()
    -- Clear screen
    gfx.sprite.update()
    pd.drawFPS(0, 0)

    local frameIndex = math.floor((pd.getCrankPosition() / 360) * moonFrameCount) + 1
    frameIndex = math.max(1, math.min(frameIndex, moonFrameCount))
    -- Update the moon sprite only if the frame changed
    if frameIndex ~= currentFrame then
        currentFrame = frameIndex
        moonSprite:setImage(moonSriteTable[currentFrame])
    end

    gfx.drawTextAligned("Score: " .. score, 390, 5, kTextAlignment.right)
end
