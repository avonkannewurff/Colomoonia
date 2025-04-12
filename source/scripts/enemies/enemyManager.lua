local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities

EnemyManager = {}
class('EnemyManager').extends()

function EnemyManager:init(moon, buildingManager)
    self.moon = moon
    self.buildingManager = buildingManager
    self.enemies = {}
    self.startEnemySpawn = false
    self.enemySpawnThreshold = 10
    self.buildingSpawnScale = 0.1
    return self
end

function EnemyManager:addEnemy(enemy)
    table.insert(self.enemies, enemy)
end

function EnemyManager:update(dt)
    for i = 1, #self.enemies do
        local enemy = self.enemies[i]
        enemy:update(dt, self.moon)

        -- Update the positions of the enemies (according to the moon's rotation)
        self:moveEnemyWithMoon(enemy)
    end

    self:removeDeadEnemies()

    -- Spawn enemies based on time elapsed
    self.enemySpawnThreshold = self.enemySpawnThreshold + dt
    local spawnInterval = 1 / self:calculateEnemySpawnRate()

    if self.enemySpawnThreshold > (spawnInterval * 300) and #self.buildingManager.buildings > 0 then
        self:spawnEnemy("creature")
        self.enemySpawnThreshold = 0 -- Reset the threshold
    end
end

function EnemyManager:calculateEnemySpawnRate()
    if not self.startEnemySpawn then
        return 0.0001 -- Very slow spawn rate initially
    end

    local gameTimeMinutes = pd.getElapsedTime() / 60
    local buildingFactor = math.min(#self.buildingManager.buildings * 0.01, 0.1)
    local timeFactor = math.min(gameTimeMinutes * 0.005, 0.1)

    -- Base rate of 0.01 (1 per 100 sec) increasing to max of 0.2 (1 per 5 sec)
    local spawnRate = 0.01 + buildingFactor + timeFactor

    -- Lower max spawn rate to 0.2 (1 every 5 seconds)
    return math.min(spawnRate, 0.2)
end

function EnemyManager:spawnEnemy(type)
    local angle = math.random() * 2 * math.pi
    local distance = self.moon.moonRadius
    local x = self.moon.moonCenterX + distance * math.cos(angle)
    local y = self.moon.moonCenterY + distance * math.sin(angle)
    local initialRotation = self.moon.overallRotations * (2 * math.pi / self.moon.crankRotationsPerFullTraversal)

    if type == "creature" then
        table.insert(self.enemies, Creature:new(x, y, initialRotation, self))
    end
end

function EnemyManager:moveEnemyWithMoon(enemy)
    local moonFrameDelta = self.moon.currentFrame - enemy.lastKnownMoonFrame

    if moonFrameDelta ~= 0 then
        -- Update the positions of the enemies (according to the moon)
        local newAngle = enemy.angle + (self.moon.totalRotation - enemy.initialRotation)
        local x = self.moon.moonCenterX + enemy.distance * math.cos(newAngle)
        local y = self.moon.moonCenterY + enemy.distance * math.sin(newAngle)
        enemy:moveTo(x, y)
        -- Update last known rotation for next frame
        enemy.lastKnownMoonFrame = self.moon.currentFrame
    end
end

function EnemyManager:stop()
    for i = 1, #self.enemies do
        local enemy = self.enemies[i]
        enemy:stop()
    end
end

function EnemyManager:removeDeadEnemies()
    for i = #self.enemies, 1, -1 do
        if self.enemies[i].delete then
            table.remove(self.enemies, i)
        end
    end
end

function EnemyManager:findNearestBuilding(enemy)
    local nearestBuilding = nil
    local nearestDistance = math.huge

    for _, building in ipairs(BuildingManager.buildings) do
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
