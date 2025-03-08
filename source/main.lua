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
assets.preloadImages({ "images/cursor" })
assets.preloadImages({ "images/house", "images/dish", "images/small_tower", "images/tank" })

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
local crankRotationsPerFullTraversal = 3 -- Number of full crank rotations required for one full traversal of the sprite table
local moonCenterX, moonCenterY = 200, 340
local moonRadius = 240
local moonFrameCount = 113
local currentFrame = 1
local moonSriteTable = assets.getImagetable("images/moon.png")
local moonSprite = gfx.sprite.new(moonSriteTable[currentFrame])
moonSprite:moveTo(moonCenterX, moonCenterY)
moonSprite:add()

-- Cursor
local cursorSpeed = 4
local cursorImage = assets.getImage("images/cursor")
local cursorSprite = gfx.sprite.new(cursorImage)
cursorSprite:moveTo(200, 120)
cursorSprite:setZIndex(100)
cursorSprite:add()

-- Buildings
local buildings = {}

-- Building images
local buildingFrameCount = 4
local currentBuildingFrame = 1
local buildingImages = {}
buildingImages[0] = assets.getImage("images/house")
buildingImages[1] = assets.getImage("images/dish")
buildingImages[2] = assets.getImage("images/small_tower")
buildingImages[3] = assets.getImage("images/tank")

local buildingSprites = {}
for i = 0, #buildingImages do
    buildingSprites[i] = gfx.sprite.new(buildingImages[i])
end

-- Track overall rotations
local overallRotations = 0
local lastCrankPosition = pd.getCrankPosition()

-- Update function for cursor movement
function updateCursor()
    local x, y = cursorSprite:getPosition()
    if pd.buttonIsPressed(pd.kButtonUp) then
        y -= cursorSpeed
    elseif pd.buttonIsPressed(pd.kButtonDown) then
        y += cursorSpeed
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        x -= cursorSpeed
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        x += cursorSpeed
    end

    -- Ensure cursor stays within the moon's bounds
    local dx = x - moonCenterX
    local dy = y - moonCenterY
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance > moonRadius then
        -- Move cursor back to the edge of the moon
        local angle = math.atan(dy, dx)
        x = moonCenterX + moonRadius * math.cos(angle)
        y = moonCenterY + moonRadius * math.sin(angle)
    end

    if y >= 224 then --make sure cursor cannot go beyond bottom of screen
        y = 224
    end

    cursorSprite:moveTo(x, y)
end

-- Function to cycle through building sprites
function cycleBuilding()
    currentBuildingFrame = (currentBuildingFrame + math.random(10)) % buildingFrameCount
end

-- Function to place a building
function placeBuilding()
    local x, y = cursorSprite:getPosition()
    local dx = x - moonCenterX
    local dy = y - moonCenterY
    local angle = math.atan(dy, dx)
    local distance = math.sqrt(dx * dx + dy * dy)
    local initialRotation = overallRotations * (2 * math.pi / crankRotationsPerFullTraversal)

    local buildingSprite = buildingSprites[currentBuildingFrame]:copy()
    local buildingx, buildingy, buildingWidth, buildingHeight = buildingSprite:getBounds()
    buildingSprite:setCollideRect(0, 0, buildingWidth, buildingHeight)
    buildingSprite:moveTo(x, y)
    buildingSprite:add()
    local overlap = buildingSprite:overlappingSprites()
    if #overlap > 0 then
        buildingSprite:remove()
        return false
    end

    table.insert(buildings,
        { sprite = buildingSprite, angle = angle, distance = distance, initialRotation = initialRotation })
    score += 1
    return true
end

-- Handle A button press to place building
function playdate.AButtonDown()
    -- Only cycle to next building once we've placed the current
    if (placeBuilding()) then
        cycleBuilding()
    end
end

-- Handle B button press to place building
function playdate.BButtonDown()
    placeBuilding()
end

function updateMoon()
    local crankPosition = pd.getCrankPosition()
    local deltaCrankPosition = crankPosition - lastCrankPosition

    -- Handle wrapping of crank position
    if deltaCrankPosition > 180 then
        deltaCrankPosition = deltaCrankPosition - 360
    elseif deltaCrankPosition < -180 then
        deltaCrankPosition = deltaCrankPosition + 360
    end

    overallRotations = overallRotations + deltaCrankPosition / 360
    lastCrankPosition = crankPosition

    local scaledCrankPosition = overallRotations / crankRotationsPerFullTraversal
    local frameIndex = math.floor((scaledCrankPosition % 1) * moonFrameCount) + 1
    frameIndex = math.max(1, math.min(frameIndex, moonFrameCount))

    -- Update the moon sprite only if the frame changed
    if frameIndex ~= currentFrame then
        currentFrame = frameIndex
        moonSprite:setImage(moonSriteTable[currentFrame])

        -- Calculate the total rotation angle of the moon
        local totalRotation = overallRotations * (2 * math.pi / crankRotationsPerFullTraversal)

        -- Update the positions of the buildings
        for _, building in ipairs(buildings) do
            local newAngle = building.angle + (totalRotation - building.initialRotation)
            local x = moonCenterX + building.distance * math.cos(newAngle)
            local y = moonCenterY + building.distance * math.sin(newAngle)
            building.sprite:moveTo(x, y)
        end
    end
end

-- playdate.update function is required in every project!
function playdate.update()
    -- Clear screen
    gfx.sprite.update()
    pd.drawFPS(0, 0)

    updateCursor()
    updateMoon()

    gfx.drawTextAligned("Score: " .. score, 390, 5, kTextAlignment.right)
end
