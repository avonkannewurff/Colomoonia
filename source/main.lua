-- Importing libraries used for drawCircleAtPoint and crankIndicator
import "CoreLibs/graphics"
import "CoreLibs/ui"
import "CoreLibs/animation"
import "CoreLibs/animator"
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
assets.preloadImages({ "images/enemy_24-24" })

-- Setup
pd.display.setRefreshRate(30)
local sasserFont = gfx.font.new("fonts/Sasser Slab/Sasser-Slab")
gfx.setImageDrawMode(gfx.kDrawModeNXOR)
gfx.setFont(sasserFont)

--Game State
local score = 0
local enemiesKilled = 0
local mode = "building"

-- Tags
TAGS = {
    building = 1,
    laser = 2,
    enemy = 3
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
local isMoonRotating = false
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
local buildingHealth = 50
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
local laserSpeed = 3
local maxLasers = 10
local lasers = {}

-- Enemies
local enemySpeed = 2
local baseSpawnRate = 0.01
local buildingsScale = 0.01
local enemySpawnTimer = 0
local enemies = {}

local enemyImage = assets.getImage("images/enemy_24-24")



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
    nextBuilding:setZIndex(50)
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

function getAngleDistRot(x, y)
    local dx = x - moonCenterX
    local dy = y - moonCenterY
    local angle = math.atan(dy, dx)
    local distance = math.sqrt(dx * dx + dy * dy)
    local initialRotation = overallRotations * (2 * math.pi / crankRotationsPerFullTraversal)
    return angle, distance, initialRotation
end

function placeBuilding()
    local x, y = buildingCursorSprite:getPosition()
    local angle, distance, initialRotation = getAngleDistRot(x, y)

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
        {
            sprite = nextBuilding,
            angle = angle,
            distance = distance,
            initialRotation = initialRotation,
            health =
                buildingHealth
        })
    score += 1
    return true
end

function fireLaser()
    local laserImage = assets.getImage("images/laser_16-16")
    local laserSprite = gfx.sprite.new(laserImage)
    laserSprite:setCollideRect(0, 0, 16, 16)
    laserSprite:setGroups({ TAGS.laser })
    laserSprite:setTag(TAGS.laser)
    laserSprite:setCollidesWithGroups({ TAGS.enemy })
    laserSprite:add()

    local startX = math.random(0, 400)
    local startY = 0
    local laserTargetX, laserTargetY = laserCursorSprite:getPosition()
    laserSprite:moveTo(startX, startY)
    laserSprite:setVisible(true)
    table.insert(lasers, { sprite = laserSprite, speed = laserSpeed, targetX = laserTargetX, targetY = laserTargetY })
end

function calculateEnemySpawnRate()
    local elapsedTime = pd.getElapsedTime()

    -- Scale spawn rate exponentially based on the number of buildings
    -- return baseSpawnRate * (1 - math.exp(-0.1 * (#buildings))) + (pd.getElapsedTime() / 10000)
    return baseSpawnRate + buildingsScale * #buildings
end

function createEnemy()
    local enemySprite = gfx.sprite.new(enemyImage)
    enemySprite:setCollideRect(0, 0, enemySprite:getSize())
    enemySprite:setZIndex(10)
    enemySprite:setGroups({ TAGS.enemy })
    enemySprite:setTag(TAGS.enemy)
    -- enemySprite.collisionResponse = function(self, other) return gfx.sprite.kCollisionTypeBounce end
    enemySprite:setCollidesWithGroups({ TAGS.laser, TAGS.building })
    enemySprite:add()
    return enemySprite
end

function spawnEnemy()
    local angle = math.random() * 2 * math.pi
    local distance = moonRadius
    local x = moonCenterX + distance * math.cos(angle)
    local y = moonCenterY + distance * math.sin(angle)
    local initialRotation = overallRotations * (2 * math.pi / crankRotationsPerFullTraversal)

    local enemySprite = createEnemy()
    enemySprite:moveTo(x, y)
    table.insert(enemies,
        {
            sprite = enemySprite,
            target = nil,
            angle = angle,
            distance = distance,
            initialRotation = initialRotation,
            speed = enemySpeed,
            health = 100
        })
end

function findNearestBuilding(enemy)
    local nearestBuilding = nil
    local nearestDistance = math.huge

    for _, building in ipairs(buildings) do
        local buildingX, buildingY = building.sprite:getPosition()
        local enemyX, enemyY = enemy.sprite:getPosition()
        local dx = buildingX - enemyX
        local dy = buildingY - enemyY
        local distance = math.sqrt(dx * dx + dy * dy)

        if distance < nearestDistance then
            nearestDistance = distance
            nearestBuilding = building
        end
    end

    return nearestBuilding
end

-- Handle A button press to perform action
function playdate.AButtonDown()
    if mode == "building" then
        -- Only cycle to next building once we've placed the current
        if (placeBuilding()) then
            cycleBuilding()
        end
    elseif mode == "laser" then
        if #lasers < maxLasers then
            fireLaser()
        end
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

    -- Update the moon rotation flag
    isMoonRotating = (deltaCrankPosition ~= 0)

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

        -- Update the positions of the enemies
        for _, enemy in ipairs(enemies) do
            local newAngle = enemy.angle + (totalRotation - enemy.initialRotation)
            local x = moonCenterX + enemy.distance * math.cos(newAngle)
            local y = moonCenterY + enemy.distance * math.sin(newAngle)
            enemy.sprite:moveTo(x, y)
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
                    if collisionTag == TAGS.enemy then
                        enemiesKilled += 1
                        local enemy = collision.other
                        laser.sprite:remove()
                        for i = #enemies, 1, -1 do
                            if enemies[i].sprite == enemy then
                                table.remove(enemies, i)
                                break
                            end
                        end
                        enemy:remove()
                        laser.delete = true
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

function updateEnemies()
    for i = #enemies, 1, -1 do
        local enemy = enemies[i]

        if not enemy.target then
            enemy.target = findNearestBuilding(enemy)
        end

        if enemy.target and not isMoonRotating and not enemy.bouncing then
            local targetx, targety = enemy.target.sprite:getPosition()
            local enemyX, enemyY = enemy.sprite:getPosition()
            local dx = targetx - enemyX
            local dy = targety - enemyY
            local distance = math.sqrt(dx * dx + dy * dy)

            local angle = math.atan(dy, dx)
            local newX = enemyX + enemySpeed * math.cos(angle)
            local newY = enemyY + enemySpeed * math.sin(angle)
            local actualX, actualY, collisions, length = enemy.sprite:moveWithCollisions(newX, newY)

            -- Update enemy's angle and distance
            local newAngle, newDistance, newInitialRotation = getAngleDistRot(actualX, actualY)
            enemy.angle = newAngle
            enemy.distance = newDistance
            enemy.initialRotation = newInitialRotation

            if length > 0 then -- Check for collisions
                for _, collision in ipairs(collisions) do
                    local collidedBuilding = collision.other
                    local collisionTag = collidedBuilding:getTag()
                    if collisionTag == TAGS.building then
                        attackBuilding(enemy, collidedBuilding)

                        -- Bounce off the building
                        local bounceAngle     = math.pi + angle -- Reverse the angle
                        local bounceX         = actualX + enemy.speed * 2 * math.cos(bounceAngle)
                        local bounceY         = actualY + enemy.speed * 2 *
                            math.sin(bounceAngle)

                        -- Create bounce animation
                        local startX, startY  = actualX, actualY
                        local endX, endY      = bounceX, bounceY
                        local duration        = { 250, 250 } -- milliseconds

                        local parts           = {
                            playdate.geometry.lineSegment.new(startX, startY, endX, endY),
                            playdate.geometry.lineSegment.new(endX, endY, startX, startY)
                        }
                        local lineIn          = playdate.geometry.lineSegment.new(startX, startY, endX, endY)
                        local lineOut         = playdate.geometry.lineSegment.new(endX, endY, startX, startY)
                        enemy.bouncing        = true
                        local easingFunctions = { pd.easingFunctions.outCubic, pd.easingFunctions.inCubic }
                        enemy.animator        = gfx.animator.new(duration, parts, easingFunctions)
                    end
                end
            end
        elseif not isMoonRotating and enemy.bouncing then
            enemy.sprite:moveTo(enemy.animator:currentValue())
            if enemy.animator and enemy.animator:ended() then
                enemy.bouncing = false
                enemy.animator = nil
            end
        end
    end
end

function attackBuilding(enemy, building)
    --get building
    local foundBuilding = nil
    for _, b in ipairs(buildings) do
        if b.sprite == building then
            foundBuilding = b
            break
        end
    end

    if not foundBuilding then
        return
    end

    -- Implement attack logic here
    foundBuilding.health -= 1
    if foundBuilding.health <= 0 then
        score -= 1
        if (enemy.target == foundBuilding) then
            enemy.target = nil
        end
        foundBuilding.sprite:remove()
        -- Remove building from the buildings table
        for i = #buildings, 1, -1 do
            if buildings[i] == foundBuilding then
                table.remove(buildings, i)
                break
            end
        end
    end
end

-- playdate.update function is required in every project!
function playdate.update()
    -- Clear screen
    gfx.sprite.update()
    pd.drawFPS(385, 225)

    if #enemies < 5 then
        local enemySpawnRate = calculateEnemySpawnRate()
        enemySpawnTimer = pd.getElapsedTime()
        if enemySpawnTimer > 1 / enemySpawnRate and #buildings > 0 then
            spawnEnemy()
            enemySpawnTimer = 0
            pd.resetElapsedTime()
        end
    end


    updateCursor()
    updateMoon()
    updateLasers()
    updateEnemies()

    gfx.drawTextAligned("Score: " .. score, 390, 5, kTextAlignment.right)
    gfx.drawTextAligned("Killed: " .. enemiesKilled, 390, 25, kTextAlignment.right)
    gfx.drawTextAligned("Ammo: " .. maxLasers - #lasers, 160, 5, kTextAlignment.right)
end

--Init
cycleBuilding()
pd.resetElapsedTime()
