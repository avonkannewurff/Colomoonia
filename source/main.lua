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

-- Preload Images and Image Tables
assets.preloadImages({ "images/stars" })
assets.preloadImages({ "images/cursor_32-32", "images/cursor_64-64" })
assets.preloadImages({ "images/house", "images/dish", "images/small_tower", "images/tank" })
assets.preloadImages({ "images/laser_16-16" })
assets.preloadImages({ "images/enemy_24-24" })
assets.preloadImages({ "images/enemy_attack_24-24" })

assets.preloadImagetable("images/moon")
assets.preloadImagetable("images/selector")
assets.preloadImagetable("images/house")
assets.preloadImagetable("images/satellite")
assets.preloadImagetable("images/small_tower")
assets.preloadImagetable("images/tank")
assets.preloadImagetable("images/enemy")

-- Setup
pd.display.setRefreshRate(30)
local sasserFont = gfx.font.new("fonts/Sasser Slab/Sasser-Slab")
gfx.setFont(sasserFont)

--Game State
local gameState = "intro" -- Initialize game state
local score = 0
local highestScore = 0
local enemiesKilled = 0
local lasersShot = 0
local mode = "building"
local crankIndicator = pd.ui.crankIndicator

-- Tags
TAGS = {
    building = 1,
    laser = 2,
    enemy = 3
}

ZINDEX = {
    moon = 0,
    building = 10,
    enemy = 30,
    laser = 50,
    cursor = 100
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
isMoonRotating = false
local moonSriteTable = assets.getImagetable("images/moon.png")
local moonSprite = gfx.sprite.new(moonSriteTable[currentFrame])
moonSprite:setZIndex(ZINDEX.moon)
moonSprite:moveTo(moonCenterX, moonCenterY)
moonSprite:add()

-- Cursor
local cursorSpeed = 4
local cursorImage = assets.getImage("images/cursor_32-32")
local buildingCursorSprite = gfx.sprite.new(cursorImage)
local selectorImagetable = assets.getImagetable("images/selector")
local laserCursorSprite = utilities.animatedSprite(200, 120, selectorImagetable, 50, true)
buildingCursorSprite:moveTo(200, 120)
buildingCursorSprite:setZIndex(ZINDEX.cursor)
buildingCursorSprite:add()

laserCursorSprite:setIgnoresDrawOffset(true)
laserCursorSprite:setVisible(false)
laserCursorSprite:setZIndex(ZINDEX.cursor)
laserCursorSprite:add()

-- Buildings
buildings = {}
local buildingHealth = 20
-- Building images
local buildingFrameCount = 4
local currentBuildingFrame = 1
local buildingImages = {}
buildingImages[1] = assets.getImage("images/house")
buildingImages[2] = assets.getImage("images/dish")
buildingImages[3] = assets.getImage("images/small_tower")
buildingImages[4] = assets.getImage("images/tank")

local buildingImagetables = {}
buildingImagetables[1] = assets.getImagetable("images/house")
buildingImagetables[2] = assets.getImagetable("images/satellite")
buildingImagetables[3] = assets.getImagetable("images/small_tower")
buildingImagetables[4] = assets.getImagetable("images/tank")

local buildingSprites = {}
for i = 0, #buildingImages do
    buildingSprites[i] = gfx.sprite.new(buildingImages[i])
end
local nextBuildingSprite

-- Lasers
local laserSpeed = 3
local maxLasers = 10
local lasers = {}

-- Enemies
local enemySpeed = 2
local baseSpawnRate = 0.01
local buildingsScale = 0.01
local enemySpawnTimer = 0
enemies = {}

local enemyImage = assets.getImage("images/enemy_24-24")
local enemyAttackImage = assets.getImage("images/enemy_attack_24-24")
local numAttackFrames = 10

-- Enemy Class
Enemy = {}
Enemy.__index = Enemy

function Enemy:new(x, y, initialRotation)
    local self = setmetatable({}, Enemy)
    self.sprite = gfx.sprite.new(enemyImage)
    self.sprite:setCollideRect(0, 0, self.sprite:getSize())
    self.sprite:setZIndex(ZINDEX.enemy)
    self.sprite:setGroups({ TAGS.enemy })
    self.sprite:setTag(TAGS.enemy)
    self.sprite:setCollidesWithGroups({ TAGS.laser, TAGS.building })
    self.sprite:moveTo(x, y)
    self.sprite:isVisible(true)
    self.sprite:add()

    self.attackSprite = utilities.animatedSprite(x, y, "images/enemy", 100, true)
    self.attackSprite:setCollideRect(0, 0, self.attackSprite:getSize())
    self.attackSprite:setZIndex(ZINDEX.enemy)
    self.attackSprite:setGroups({ TAGS.enemy })
    self.attackSprite:setTag(TAGS.enemy)
    self.attackSprite:setCollidesWithGroups({ TAGS.laser, TAGS.building })
    self.attackSprite:moveTo(x, y)
    self.attackSprite:setVisible(false)
    self.attackSprite:add()

    self.target = nil
    self.angle = 0
    self.distance = 0
    self.initialRotation = initialRotation
    self.speed = enemySpeed
    self.health = 100
    self.attacking = false

    return self
end

--Currently always moving both sprites because they both need to move when the moon rotates
-- This function is only called to adjust for moon rotation
function Enemy:moveTo(x, y)
    self.attackSprite:moveTo(x, y)
    self.sprite:moveTo(x, y)
end

function Enemy:moveWithCollisions(x, y)
    if self.attacking then
        self.sprite:moveWithCollisions(x, y)
        return self.attackSprite:moveWithCollisions(x, y)
    else
        self.attackSprite:moveWithCollisions(x, y)
        return self.sprite:moveWithCollisions(x, y)
    end
end

function Enemy:startAttack()
    local x, y = self.sprite:getPosition()
    self:moveTo(x, y)
    self.attackSprite:setVisible(true)
    self.sprite:setVisible(false)
    self.attacking = true
end

function Enemy:stopAttack()
    self.attacking = false
    self.attackSprite:setVisible(false)
    self.sprite:setVisible(true)
end

-- Building Class
Building = {}
Building.__index = Building

function Building:new(x, y, buildingType, angle, distance, initialRotation)
    local self = setmetatable({}, Building)
    self.index = buildingType
    self.sprite = nextBuildingSprite:copy()
    self.sprite:setZIndex(ZINDEX.building)
    self.sprite:setGroups({ TAGS.building })
    self.sprite:setTag(TAGS.building)
    self.sprite:setCollidesWithGroups({ TAGS.building, TAGS.laser })
    local buildingx, buildingy, buildingWidth, buildingHeight = self.sprite:getBounds()
    self.sprite:setCollideRect(0, 0, buildingWidth, buildingHeight)
    self.sprite:moveTo(x, y)

    self.sprite:add()

    self.angle = angle
    self.distance = distance
    self.initialRotation = initialRotation
    self.health = buildingHealth

    return self
end

-- Track overall rotations
local overallRotations = 0
local lastCrankPosition = pd.getCrankPosition()

function updateCursor()
    local x, y = buildingCursorSprite:getPosition()
    if mode == "building" then
        local buildingx, buildingy, buildingWidth, buildingHeight = nextBuildingSprite:getBounds()
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

function cycleBuildingSprite()
    if nextBuildingSprite then
        nextBuildingSprite:remove()
    end
    currentBuildingFrame = (currentBuildingFrame + math.random(2)) % buildingFrameCount + 1
    nextBuildingSprite = buildingSprites[currentBuildingFrame]:copy()
    nextBuildingSprite:setZIndex(ZINDEX.building)
    nextBuildingSprite:setGroups({ TAGS.building })
    nextBuildingSprite:setTag(TAGS.building)
    nextBuildingSprite:setCollidesWithGroups({ TAGS.building, TAGS.laser })
    local buildingx, buildingy, buildingWidth, buildingHeight = nextBuildingSprite:getBounds()
    if buildingWidth == 32 then
        nextBuildingSprite:moveTo(16, 16)
    elseif buildingWidth == 64 then
        nextBuildingSprite:moveTo(32, 32)
    end
    nextBuildingSprite:add()
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

    local building = Building:new(x, y, currentBuildingFrame, angle, distance, initialRotation)
    local overlap = building.sprite:overlappingSprites()
    if #overlap > 0 then
        building.sprite:remove()
        return false
    end
    table.insert(buildings, building)
    score += 1
    highestScore += 1
    return true
end

function fireLaser()
    local laserImage = assets.getImage("images/laser_16-16")
    local laserSprite = gfx.sprite.new(laserImage)
    laserSprite:setCollideRect(0, 0, 16, 16)
    laserSprite:setGroups({ TAGS.laser })
    laserSprite:setTag(TAGS.laser)
    laserSprite:setZIndex(ZINDEX.laser)
    laserSprite:setCollidesWithGroups({ TAGS.enemy })
    laserSprite:add()

    lasersShot += 1

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

function spawnEnemy()
    local angle = math.random() * 2 * math.pi
    local distance = moonRadius
    local x = moonCenterX + distance * math.cos(angle)
    local y = moonCenterY + distance * math.sin(angle)
    local initialRotation = overallRotations * (2 * math.pi / crankRotationsPerFullTraversal)

    local enemy = Enemy:new(x, y, initialRotation)
    table.insert(enemies, enemy)
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
    if gameState == "intro" then
        gameState = "instructions"
    elseif gameState == "instructions" then
        gameState = "playing"
        cycleBuildingSprite() -- Initialize the first building
        pd.resetElapsedTime() -- Reset the game timer
    elseif gameState == "playing" then
        -- Existing A button logic
        if mode == "building" then
            if (placeBuilding()) then
                cycleBuildingSprite()
            end
        elseif mode == "laser" then
            if #lasers < maxLasers then
                fireLaser()
            end
        end
    elseif gameState == "gameOver" then
        -- Reset game variables and restart the game
        score = 0
        enemiesKilled = 0
        buildings = {}
        lasers = {}
        enemies = {}
        gameState = "playing"
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
    isMoonRotating = (math.abs(deltaCrankPosition) > 0.1) -- Check for a minimum crank movement

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
            enemy:moveTo(x, y)
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
                        local foundEnemy = nil
                        for _, e in ipairs(enemies) do
                            if e.sprite == enemy or e.attackSprite == enemy then
                                foundEnemy = e
                                foundEnemy.attackSprite:remove()
                                foundEnemy.sprite:remove()
                                break
                            end
                        end
                        if foundEnemy then
                            for i = #enemies, 1, -1 do
                                if enemies[i] == foundEnemy then
                                    table.remove(enemies, i)
                                    break
                                end
                            end
                        else
                            print("Enemy not found")
                        end
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

        if enemy.target and not isMoonRotating then
            local targetx, targety = enemy.target.sprite:getPosition()
            local enemyX, enemyY = enemy.sprite:getPosition()
            local dx = targetx - enemyX
            local dy = targety - enemyY
            local distance = math.sqrt(dx * dx + dy * dy)

            local angle = math.atan(dy, dx)
            local newX = enemyX + enemy.speed * math.cos(angle)
            local newY = enemyY + enemy.speed * math.sin(angle)
            local actualX, actualY, collisions, length = enemy:moveWithCollisions(newX, newY)

            -- Update enemy's angle and distance
            -- This is needed to make sure that the enemies don't jump in movement during the next moon rotation
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
                    end
                end
            else
                if enemy.attacking then
                    enemy:stopAttack()
                    enemy.target = findNearestBuilding(enemy)
                end
            end
        elseif enemy.target and not isMoonRotating and not enemy.attacking then
            if not enemy.target.sprite then
                enemy.target = findNearestBuilding(enemy)
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
        enemy:stopAttack()
        enemy.target = nil
        return
    end

    --TODO : Flip on x as needed
    if not enemy.attacking then
        enemy:startAttack()
    end

    -- Implement attack logic here
    foundBuilding.health -= 0.1
    if foundBuilding.health <= 0 then
        score -= 1
        if (enemy.target == foundBuilding) then
            enemy.target = nil
        end

        enemy:stopAttack()
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


    if gameState == "intro" then
        drawIntroScreen()
        return
    elseif gameState == "instructions" then
        drawInstrunctionsScreen()
        return
    elseif gameState == "playing" then
        gfx.sprite.update()
        if pd.isCrankDocked() then
            gfx.setImageDrawMode(gfx.kDrawModeCopy)
            crankIndicator:draw()
        end
        pd.drawFPS(0, 225)
        if score <= 0 and #enemies > 0 then
            gameState = "gameOver"
            return
        end

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

        gfx.setImageDrawMode(gfx.kDrawModeNXOR)
        gfx.drawTextAligned("Buildings: " .. score, 390, 5, kTextAlignment.right)
        gfx.drawTextAligned("Zapped: " .. enemiesKilled, 390, 25, kTextAlignment.right)
        gfx.drawTextAligned("Lasers: " .. maxLasers - #lasers, 160, 5, kTextAlignment.right)
    elseif gameState == "gameOver" then
        drawGameOverScreen()
    end
end

function drawIntroScreen()
    gfx.clear()
    gfx.drawTextAligned("Colomoonia!", 200, 30, kTextAlignment.center)
    gfx.drawTextAligned("Build your colony", 200, 100, kTextAlignment.center)
    gfx.drawTextAligned("and protect it from moon creatures!", 200, 120, kTextAlignment.center)
    gfx.drawTextAligned("Press A to continue", 200, 220, kTextAlignment.center)
end

function drawInstrunctionsScreen()
    gfx.clear()
    gfx.drawTextAligned("Controls", 200, 30, kTextAlignment.center)
    gfx.drawTextAligned("- Use the crank to rotate the moon", 10, 90, kTextAlignment.left)
    gfx.drawTextAligned("- Press A to place buildings or shoot lasers", 10, 110, kTextAlignment.left)
    gfx.drawTextAligned("- Press B to toggle building/laser mode", 10, 130, kTextAlignment.left)
    gfx.drawTextAligned("Press A to start", 200, 220, kTextAlignment.center)
end

function drawGameOverScreen()
    gfx.clear()
    gfx.drawTextAligned("Game Over", 200, 30, kTextAlignment.center)
    gfx.drawTextAligned("Total Buldings Placed: " .. highestScore, 200, 90, kTextAlignment.center)
    gfx.drawTextAligned("Lasers Shot: " .. lasersShot, 200, 110, kTextAlignment.center)
    gfx.drawTextAligned("Creatures Zapped: " .. enemiesKilled, 200, 130, kTextAlignment.center)
    gfx.drawTextAligned("Press A to Restart", 200, 220, kTextAlignment.center)
end

--Init
cycleBuildingSprite()
pd.resetElapsedTime()
-- spawnEnemy()
