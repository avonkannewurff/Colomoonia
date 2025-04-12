local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities

Cursor = {}
class('Cursor').extends(gfx.sprite)
local cursorImage = assets.getImage("images/cursor_32-32")
local selectorImagetable = assets.getImagetable("images/selector")

function Cursor:init(x, y, moon, buildingManager)
    local self = setmetatable({}, Cursor)
    self.mode = "building";

    self.buildingCursorSprite = gfx.sprite.new(cursorImage)
    self.laserCursorSprite = utilities.animatedSprite(x, y, selectorImagetable, 50, true)
    self.buildingCursorSprite:moveTo(x, y)
    self.buildingCursorSprite:setZIndex(Z_INDEXES.cursor)
    self.buildingCursorSprite:add()

    self.laserCursorSprite:setIgnoresDrawOffset(true)
    self.laserCursorSprite:setVisible(false)
    self.laserCursorSprite:setZIndex(Z_INDEXES.cursor)
    self.laserCursorSprite:add()

    self.cursorSpeed = 7

    self.moon = moon
    self.buildingManager = buildingManager

    self.stopped = false
    return self
end

function Cursor:new()

end

function Cursor:update()
    local x, y = self.buildingCursorSprite:getPosition()
    if self.mode == "building" then
        local buildingx, buildingy, buildingWidth, buildingHeight = self.buildingManager.nextBuildingSprite:getBounds()
        if buildingWidth == 32 then
            cursorImage = assets.getImage("images/cursor_32-32")
        elseif buildingWidth == 64 then
            cursorImage = assets.getImage("images/cursor_64-64")
        end
        self.buildingCursorSprite:setImage(cursorImage)
        self.buildingCursorSprite:setVisible(true)
        self.laserCursorSprite:setVisible(false)
    elseif self.mode == "laser" then
        self.laserCursorSprite:moveTo(x, y)
        self.buildingCursorSprite:setVisible(false)
        self.laserCursorSprite:setVisible(true)
    end

    if pd.buttonIsPressed(pd.kButtonUp) then
        y -= self.cursorSpeed
    elseif pd.buttonIsPressed(pd.kButtonDown) then
        y += self.cursorSpeed
    elseif pd.buttonIsPressed(pd.kButtonLeft) then
        x -= self.cursorSpeed
    elseif pd.buttonIsPressed(pd.kButtonRight) then
        x += self.cursorSpeed
    end

    if pd.buttonJustPressed(pd.kButtonB) then
        self:toggleMode()
    end

    -- Ensure cursor stays within the moon's bounds
    local dx = x - self.moon.moonCenterX
    local dy = y - self.moon.moonCenterY
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance > self.moon.moonRadius then
        -- Move cursor back to the edge of the moon
        local angle = math.atan(dy, dx)
        x = self.moon.moonCenterX + self.moon.moonRadius * math.cos(angle)
        y = self.moon.moonCenterY + self.moon.moonRadius * math.sin(angle)
    end

    if y >= 224 then --make sure cursor cannot go beyond bottom of screen
        y = 224
    end

    self.buildingCursorSprite:moveTo(x, y)
    self.laserCursorSprite:moveTo(x, y)
end

function Cursor:toggleMode()
    if self.mode == "building" then
        self.mode = "laser"
    else
        self.mode = "building"
    end
end

function Cursor:stop()
    self.stopped = true
end
