local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities
local audioManager <const> = AudioManager

-- Building Class
Building = {}
class('Building').extends(gfx.sprite)
Building.__index = Building

local buildingHealth = 10

function Building:new(x, y, buildingType, angle, distance, initialRotation, nextBuildingSprite)
    local self = setmetatable({}, Building)
    self.index = buildingType
    self.sprite = nextBuildingSprite:copy()
    self.sprite:setZIndex(Z_INDEXES.building)
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

-- Better name, maybe 2 funcs
function Building:buildingDestroyed(attackVal)
    self.health -= attackVal
    if self.health <= 0 then
        audioManager.play(audioManager.sfx.crumble, 1)
        self:remove()
    else
        return false
    end
end

function Building:remove()
    self.sprite:remove()
    -- Remove building from the buildings table (will be cleaned up by manager)
    self.delete = true;
end
