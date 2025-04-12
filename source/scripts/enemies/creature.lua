local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities
local audioManager <const> = AudioManager

Creature = {}
class('Creature').extends(gfx.sprite)
Creature.__index = Creature

local creatureSpeed = 2

-- TODO: Update to inherit from Enemy class, override functions as needed
function Creature:new(x, y, initialRotation, enemyManager)
    local self = setmetatable({}, Creature)

    --play sound
    audioManager.play(audioManager.sfx.creatureSpawn, 1)

    -- Load assets
    local creatureImage = assets.getImage("images/creature_24-24")

    -- Create main sprite
    self.sprite = gfx.sprite.new(creatureImage)
    self.sprite:setCollideRect(0, 0, self.sprite:getSize())
    self.sprite:setZIndex(Z_INDEXES.creature)
    self.sprite:setGroups({ TAGS.creature })
    self.sprite:setTag(TAGS.creature)
    self.sprite:setCollidesWithGroups({ TAGS.laser, TAGS.building })
    self.sprite:moveTo(x, y)
    self.sprite:setVisible(true)
    self.sprite:add()

    -- Create attack animation sprite
    self.attackSprite = utilities.animatedSprite(x, y, "images/creature", 100, true)
    self.attackSprite:setCollideRect(0, 0, self.attackSprite:getSize())
    self.attackSprite:setZIndex(Z_INDEXES.creature)
    self.attackSprite:setGroups({ TAGS.creature })
    self.attackSprite:setTag(TAGS.creature)
    self.attackSprite:setCollidesWithGroups({ TAGS.laser, TAGS.building })
    self.attackSprite:moveTo(x, y)
    self.attackSprite:setVisible(false)
    self.attackSprite:add()

    -- Initialize properties
    self.target = nil
    self.angle = 0
    self.distance = 0
    self.initialRotation = initialRotation
    self.speed = creatureSpeed
    self.health = 100
    self.attacking = false
    self.lastKnownMoonFrame = 1

    self.enemyManager = enemyManager

    return self
end

function Creature:update()
    if not self.target then
        self.target = self.enemyManager:findNearestBuilding(self)
    end

    if self.target and not self.enemyManager.moon.isMoonRotating then
        local targetx, targety = self.target.sprite:getPosition()
        local enemyX, enemyY = self.sprite:getPosition()
        local dx = targetx - enemyX
        local dy = targety - enemyY
        local distance = math.sqrt(dx * dx + dy * dy)

        local angle = math.atan(dy, dx)
        local newX = enemyX + self.speed * math.cos(angle)
        local newY = enemyY + self.speed * math.sin(angle)
        local actualX, actualY, collisions, length = self:moveWithCollisions(newX, newY)

        -- Update enemy's angle and distance
        -- This is needed to make sure that the enemies don't jump in movement during the next moon rotation
        local newAngle, newDistance, newInitialRotation = self.enemyManager.moon:getAngleDistRot(actualX, actualY)
        self.angle = newAngle
        self.distance = newDistance
        self.initialRotation = newInitialRotation

        if length > 0 then -- Check for collisions
            for _, collision in ipairs(collisions) do
                local collidedBuilding = collision.other
                local collisionTag = collidedBuilding:getTag()
                if collisionTag == TAGS.building then
                    self:attackBuilding(collidedBuilding)
                end
                if collisionTag == TAGS.laser then
                    local laser = collision.other
                    laser:remove()
                    self:remove()
                    ENEMIES_KILLED += 1
                end
            end
        else
            if self.attacking then
                self:stopAttack()
                self.target = self.enemyManager:findNearestBuilding(self)
            end
        end
    elseif self.target and not self.enemyManager.moon.isMoonRotating and not self.attacking then
        if not self.target.sprite then
            self.target = self.enemyManager:findNearestBuilding(self)
        end
    end
end

function Creature:moveTo(x, y)
    -- Move the appropriate sprite based on state
    if self.attacking then
        self.attackSprite:moveTo(x, y)
    else
        self.sprite:moveTo(x, y)
    end
end

function Creature:moveWithCollisions(x, y)
    -- Move with collision detection using the appropriate sprite
    if self.attacking then
        return self.attackSprite:moveWithCollisions(x, y)
    else
        return self.sprite:moveWithCollisions(x, y)
    end
end

function Creature:getPosition()
    -- Get the position of the active sprite
    if self.attacking then
        return self.attackSprite:getPosition()
    else
        return self.sprite:getPosition()
    end
end

function Creature:startAttack()
    -- Switch to attack animation
    local x, y = self.sprite:getPosition()
    self.attackSprite:moveTo(x, y)
    self.attackSprite:setVisible(true)
    self.sprite:setVisible(false)
    self.attacking = true
end

function Creature:attackBuilding(building)
    --get building

    local foundBuilding = self.enemyManager.buildingManager:findBuilding(building)

    if not foundBuilding then
        self:stopAttack()
        self.target = nil
        return
    end

    --TODO : Flip on x as needed
    if not self.attacking then
        self:startAttack()
    end

    -- Check if the attack destroys the building
    if foundBuilding:buildingDestroyed(0.1) then
        if (self.target == foundBuilding) then
            self.target = nil
        end
        self:stopAttack()
    end
end

function Creature:stopAttack()
    -- Return to normal state
    if self.attacking then
        local x, y = self.attackSprite:getPosition()
        self.sprite:moveTo(x, y)
        self.attacking = false
        self.attackSprite:setVisible(false)
        self.sprite:setVisible(true)
    end
end

function Creature:remove()
    -- Clean up both sprites and mark enemy for removal by enemyManager
    audioManager.play(audioManager.sfx.creatureDeath, 1)
    self.delete = true
    self.sprite:remove()
    self.attackSprite:remove()
end

return Creature
