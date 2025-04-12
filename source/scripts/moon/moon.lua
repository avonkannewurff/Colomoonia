local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities

Moon = {}
class('Moon').extends(gfx.sprite)

assets.preloadImagetable("images/moon")

function Moon:init()
    local self = setmetatable({}, Moon)

    self.crankRotationsPerFullTraversal = 3 -- Number of full crank rotations required for one full traversal of the sprite table
    self.moonCenterX, self.moonCenterY = 200, 300
    self.moonRadius = 240
    self.moonFrameCount = 113
    self.currentFrame = 1
    self.isMoonRotating = false
    self.overallRotations = 0
    self.totalRotation = 0
    self.lastCrankPosition = pd.getCrankPosition()
    self.moonSriteTable = assets.getImagetable("images/moon.png")
    self.moonSprite = gfx.sprite.new(self.moonSriteTable[self.currentFrame])
    self.moonSprite:setZIndex(Z_INDEXES.moon)
    self.moonSprite:moveTo(self.moonCenterX, self.moonCenterY)
    self.moonSprite:add()

    return self
end

function Moon:update()
    local crankPosition = pd.getCrankPosition()
    local deltaCrankPosition = crankPosition - self.lastCrankPosition

    -- Handle wrapping of crank position
    if deltaCrankPosition > 180 then
        deltaCrankPosition = deltaCrankPosition - 360
    elseif deltaCrankPosition < -180 then
        deltaCrankPosition = deltaCrankPosition + 360
    end

    self.overallRotations = self.overallRotations + deltaCrankPosition / 360
    self.lastCrankPosition = crankPosition

    -- Update the moon rotation flag
    self.isMoonRotating = (math.abs(deltaCrankPosition) > 0.1) -- Check for a minimum crank movement

    local frameIndex = self:getFrameIndex()

    -- Update the moon sprite only if the frame changed
    if frameIndex ~= self.currentFrame then
        self.currentFrame = frameIndex

        self.moonSprite:setImage(self.moonSriteTable[self.currentFrame])

        -- Calculate the total rotation angle of the moon
        self.totalRotation = self.overallRotations * (2 * math.pi / self.crankRotationsPerFullTraversal)
    end
end

function Moon:getFrameIndex()
    local scaledCrankPosition = self.overallRotations / self.crankRotationsPerFullTraversal
    local frameIndex = math.floor((scaledCrankPosition % 1) * self.moonFrameCount) + 1
    return math.max(1, math.min(frameIndex, self.moonFrameCount))
end

function Moon:getAngleDistRot(x, y)
    local dx = x - self.moonCenterX
    local dy = y - self.moonCenterY
    local angle = math.atan(dy, dx)
    local distance = math.sqrt(dx * dx + dy * dy)
    local initialRotation = self.overallRotations * (2 * math.pi / self.crankRotationsPerFullTraversal)
    return angle, distance, initialRotation
end
