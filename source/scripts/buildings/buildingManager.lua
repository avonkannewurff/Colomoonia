local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities
local audioManager <const> = AudioManager


local buildingImages = {}
buildingImages[1] = assets.getImage("images/house")
buildingImages[2] = assets.getImage("images/dish")
buildingImages[3] = assets.getImage("images/small_tower")
buildingImages[4] = assets.getImage("images/tank")

BuildingManager = {}
class('BuildingManager').extends()

function BuildingManager:init(moon)
    self.buildings = {}
    self.moon = moon
    -- TODO: should this be static?
    self.buildingSprites = {}
    for i = 0, #buildingImages do
        self.buildingSprites[i] = gfx.sprite.new(buildingImages[i])
    end

    -- Generate the first building to be placed
    self.nextBuildingSprite   = nil
    self.currentBuildingFrame = 1
    self:cycleBuildingSprite()
    return self
end

function BuildingManager:removeBuildings()
    for i = #self.buildings, 1, -1 do
        if self.buildings[i].delete then
            table.remove(self.buildings, i)
        end
    end
end

function BuildingManager:findBuilding(building)
    for _, b in ipairs(self.buildings) do
        if b.sprite == building then
            return b
        end
    end
    return nil
end

function BuildingManager:placeBuilding(buildingCursorSprite)
    local x, y = buildingCursorSprite:getPosition()
    local angle, distance, initialRotation = self.moon:getAngleDistRot(x, y)

    local building = Building:new(x, y, self.currentBuildingFrame, angle, distance, initialRotation,
        self.nextBuildingSprite)
    local overlap = building.sprite:overlappingSprites()
    if #overlap > 0 then
        building:remove()
        return false
    end
    audioManager.play(AudioManager.sfx.buildingPlace, 1)
    table.insert(self.buildings, building)
    TOTAL_BUILDINGS_PLACED += 1
    return true
end

function BuildingManager:update(dt)
    for i = 1, #self.buildings do
        local building = self.buildings[i]
        -- building:update(dt)


        -- Update the positions of the buildings (according to the mooon)
        local newAngle = building.angle + (self.moon.totalRotation - building.initialRotation)
        local x = self.moon.moonCenterX + building.distance * math.cos(newAngle)
        local y = self.moon.moonCenterY + building.distance * math.sin(newAngle)
        building.sprite:moveTo(x, y)
    end

    self:removeBuildings()
end

function BuildingManager:cycleBuildingSprite()
    if self.nextBuildingSprite then
        self.nextBuildingSprite:remove()
    end
    self.currentBuildingFrame = (self.currentBuildingFrame + math.random(2)) % #self.buildingSprites + 1
    self.nextBuildingSprite = self.buildingSprites[self.currentBuildingFrame]:copy()
    self.nextBuildingSprite:setZIndex(Z_INDEXES.building)
    self.nextBuildingSprite:setGroups({ TAGS.building })
    self.nextBuildingSprite:setTag(TAGS.building)
    self.nextBuildingSprite:setCollidesWithGroups({ TAGS.building, TAGS.laser })
    local buildingx, buildingy, buildingWidth, buildingHeight = self.nextBuildingSprite:getBounds()
    if buildingWidth == 32 then
        self.nextBuildingSprite:moveTo(16, 16)
    elseif buildingWidth == 64 then
        self.nextBuildingSprite:moveTo(32, 32)
    end
    self.nextBuildingSprite:add()
end

function BuildingManager:stop()
    for i = 1, #self.buildings do
        local buliding = self.buildings[i]
        buliding:stop()
    end
end
