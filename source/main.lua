-- Importing libraries used for drawCircleAtPoint and crankIndicator
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/animation"
import "libraries/Assets"
import "libraries/Utilities"

-- Localizing commonly used globals
local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities

-- Preload Images
assets.preloadImages({ "images/stars" })
assets.preloadImagetable("images/moon.png")
assets.preloadImagetable("images/selector")
assets.preloadImages({ "images/cursor_32-32", "images/cursor_64-64" })
assets.preloadImages({ "images/house", "images/dish", "images/small_tower", "images/tank" })
assets.preloadImages({ "images/laser_16-16" })

-- Setup
pd.display.setRefreshRate(30)
local sasserFont = gfx.font.new("fonts/Sasser Slab/Sasser-Slab")
gfx.setImageDrawMode(gfx.kDrawModeNXOR)
gfx.setFont(sasserFont)

--Game State
local score = 0
local mode = "building"

-- Tags
TAGS = {
    building = 1,
    laser = 2
}

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
local cursorImage = assets.getImage("images/cursor_32-32")
local buildingCursorSprite = gfx.sprite.new(cursorImage)
local selectorImagetable = assets.getImagetable("images/selector")
local laserCursorSprite = utilities.animatedSprite(200, 120, selectorImagetable, 50, true)
buildingCursorSprite:moveTo(200, 120)
buildingCursorSprite:setZIndex(100)
buildingCursorSprite:add()

laserCursorSprite:setIgnoresDrawOffset(true)
laserCursorSprite:setVisible(false)
laserCursorSprite:setZIndex(100)
laserCursorSprite:add()

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
local nextBuilding

-- Lasers
local laserSpeed = 2
local lasers = {}

-- Track overall rotations
local overallRotations = 0
local lastCrankPosition = pd.getCrankPosition()

function updateCursor()
    local x, y = buildingCursorSprite:getPosition()
    if mode == "building" then
        local buildingx, buildingy, buildingWidth, buildingHeight = nextBuilding:getBounds()
        if buildingWidth == 32 then
            cursorImage = assets.getImage("images/cursor_32-32")
        elseif buildingWidth == 64 then
            cursorImage = assets.getImage("images/cursor_64-64")
        end
        buildingCursorSprite:setImage(cursorImage)
        buildingCursorSprite:setVisible(true)
        laserCursorSprite:setVisible(false)
    elseif mode == "laser" then
        laserCursorSprite:moveTo(x, y)
        buildingCursorSprite:setVisible(false)
        laserCursorSprite:setVisible(true)
    end

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

    buildingCursorSprite:moveTo(x, y)
    laserCursorSprite:moveTo(x, y)
end

function cycleBuilding()
    currentBuildingFrame = (currentBuildingFrame + math.random(2)) % buildingFrameCount
    nextBuilding = buildingSprites[currentBuildingFrame]:copy()
    nextBuilding:setGroups({ TAGS.building })
    nextBuilding:setTag(TAGS.building)
    nextBuilding:setCollidesWithGroups({ TAGS.building, TAGS.laser })
    local buildingx, buildingy, buildingWidth, buildingHeight = nextBuilding:getBounds()
    if buildingWidth == 32 then
        nextBuilding:moveTo(16, 16)
    elseif buildingWidth == 64 then
        nextBuilding:moveTo(32, 32)
    end
    nextBuilding:add()
end

function placeBuilding()
    local x, y = buildingCursorSprite:getPosition()
    local dx = x - moonCenterX
    local dy = y - moonCenterY
    local angle = math.atan(dy, dx)
    local distance = math.sqrt(dx * dx + dy * dy)
    local initialRotation = overallRotations * (2 * math.pi / crankRotationsPerFullTraversal)

    local buildingx, buildingy, buildingWidth, buildingHeight = nextBuilding:getBounds()
    nextBuilding:setCollideRect(0, 0, buildingWidth, buildingHeight)
    nextBuilding:moveTo(x, y)
    nextBuilding:add()
    local overlap = nextBuilding:overlappingSprites()
    if #overlap > 0 then
        if buildingWidth == 32 then
            nextBuilding:moveTo(16, 16)
        elseif buildingWidth == 64 then
            nextBuilding:moveTo(32, 32)
        end
        return false
    end
    table.insert(buildings,
        { sprite = nextBuilding, angle = angle, distance = distance, initialRotation = initialRotation })
    score += 1
    return true
end

function fireLaser()
    local laserImage = assets.getImage("images/laser_16-16")
    local laserSprite = gfx.sprite.new(laserImage)
    laserSprite:setCollideRect(0, 0, 16, 16)
    laserSprite:setGroups({ TAGS.laser })
    laserSprite:setTag(TAGS.laser)
    laserSprite:setCollidesWithGroups({ TAGS.building })
    laserSprite:add()

    local startX = math.random(0, 400)
    local startY = 0
    local laserTargetX, laserTargetY = laserCursorSprite:getPosition()
    laserSprite:moveTo(startX, startY)
    laserSprite:setVisible(true)
    table.insert(lasers, { sprite = laserSprite, speed = laserSpeed, targetX = laserTargetX, targetY = laserTargetY })
end

-- Handle A button press to perform action
function playdate.AButtonDown()
    if mode == "building" then
        -- Only cycle to next building once we've placed the current
        if (placeBuilding()) then
            cycleBuilding()
        end
    elseif mode == "laser" then
        fireLaser()
    end
end

-- Handle B button press to place building
function playdate.BButtonDown()
    if mode == "building" then
        mode = "laser"
    else
        mode = "building"
    end
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

function updateLasers()
    for _, laser in ipairs(lasers) do
        local x, y = laser.sprite:getPosition()
        local dx = laser.targetX - x
        local dy = laser.targetY - y
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance < laser.speed then
            laser.sprite:remove()
            -- table.remove(lasers, _)
            laser.delete = true
        else
            local angle = math.atan(dy, dx)
            x = x + laser.speed * math.cos(angle)
            y = y + laser.speed * math.sin(angle)

            local _actualX, _actualY, collisions, length = laser.sprite:moveWithCollisions(x, y)
            if length > 0 then -- Check for collisions
                for _, collision in ipairs(collisions) do
                    local collisionTag = collision.other:getTag()
                    if collisionTag == TAGS.building then
                        laser.sprite:remove()
                        collision.other:remove()
                        laser.delete = true
                        score -= 1
                    end
                end
            end
        end
    end

    for _, laser in ipairs(lasers) do
        if laser.delete then
            table.remove(lasers, _)
        end
    end
end

-- playdate.update function is required in every project!
function playdate.update()
    -- Clear screen
    gfx.sprite.update()
    pd.drawFPS(385, 225)

    updateCursor()
    updateMoon()
    updateLasers()

    gfx.drawTextAligned("Score: " .. score, 390, 5, kTextAlignment.right)
end

--Init
cycleBuilding()
