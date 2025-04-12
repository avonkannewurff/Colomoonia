local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets


local previousTime = nil
local crankIndicator = pd.ui.crankIndicator

GameScene = {}
class('GameScene').extends()


function GameScene:init()
    self.transitioning = false
    self:setUpLevel()
    self.enteringScene = true
end

function GameScene:update()
    local dt = playdate.getElapsedTime()

    if #self.buildingManager.buildings <= 0 and #self.enemyManager.enemies > 0 and not self.transitioning then
        SceneManager.switchScene(GameOverScene)
        self.transitioning = true
    end

    if self.cursor then
        self.cursor:update()
    end
    if self.moon then
        self.moon:update()
    end
    if self.buildingManager then
        self.buildingManager:update(dt)
    end
    if self.weaponManager then
        self.weaponManager:update(dt)
    end
    if self.enemyManager then
        self.enemyManager:update(dt)
    end

    if pd.isCrankDocked() then
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        crankIndicator:draw()
    end

    if pd.buttonJustPressed(pd.kButtonA) then
        if self.cursor.mode == "building" then
            if (self.buildingManager:placeBuilding(self.cursor.buildingCursorSprite)) then
                self.buildingManager:cycleBuildingSprite()

                --If this is the first building, start the game timer for enemy spawning
                if #self.buildingManager.buildings == 1 then
                    pd.resetElapsedTime()
                    self.enemyManager.startEnemySpawn = true
                end
            end
        elseif self.cursor.mode == "laser" then
            self.weaponManager:fireLaser(self.cursor.laserCursorSprite)
        end
    end

    --update highest building count for scores
    HIGHEST_BUILDING_COUNT = math.max(HIGHEST_BUILDING_COUNT, #self.buildingManager.buildings)

    if DRAW_FPS then
        pd.drawFPS(0, 225)
    end

    self:drawGameText()
end

function GameScene:setUpLevel()
    -- background
    local starsImage = assets.getImage("images/stars")
    local starsSprite = gfx.sprite.new(starsImage)
    starsSprite:setIgnoresDrawOffset(true)
    starsSprite:moveTo(200, 120)
    starsSprite:add()


    self.lastCrankPosition = pd.getCrankPosition()

    self.moon = Moon:init()
    self.weaponManager = WeaponManager:init()
    self.buildingManager = BuildingManager:init(self.moon)
    self.enemyManager = EnemyManager:init(self.moon, self.buildingManager)
    self.cursor = Cursor:init(200, 120, self.moon, self.buildingManager)

    TOTAL_BUILDINGS_PLACED = 0
    HIGHEST_BUILDING_COUNT = 0
    ENEMIES_KILLED = 0
end

function GameScene:drawGameText()
    gfx.setImageDrawMode(gfx.kDrawModeNXOR)
    gfx.drawTextAligned("Buildings: " .. #self.buildingManager.buildings, 390, 5, kTextAlignment.right)
    gfx.drawTextAligned("Zapped: " .. ENEMIES_KILLED, 390, 25, kTextAlignment.right)
    gfx.drawTextAligned("Lasers: " .. self.weaponManager.maxWeapons - #self.weaponManager.weapons, 160, 5,
        kTextAlignment.right)
end
