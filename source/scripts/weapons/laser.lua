local pd <const> = playdate
local gfx <const> = pd.graphics
local assets <const> = Assets
local utilities <const> = Utilities
local audioManager <const> = AudioManager

Laser = {}
class('Laser').extends(gfx.sprite)
Laser.__index = Laser

function Laser:new(laserCursorSprite)
    local self = setmetatable({}, Laser)

    audioManager.play(audioManager.sfx.laserFire, 1)
    local laserImage = assets.getImage("images/laser_16-16")
    self.sprite = gfx.sprite.new(laserImage)
    self.sprite:setCollideRect(0, 0, 16, 16)
    self.sprite:setGroups({ TAGS.laser })
    self.sprite:setTag(TAGS.laser)
    self.sprite:setZIndex(Z_INDEXES.laser)
    self.sprite:setCollidesWithGroups({ TAGS.enemy })
    self.sprite:add()

    LASERS_SHOT += 1

    self.x = math.random(0, 400)
    self.y = 0
    self.speed = 3
    self.targetX, self.targetY = laserCursorSprite:getPosition()
    self.sprite:moveTo(self.x, self.y)
    self.sprite:setVisible(true)
    -- table.insert(lasers, { sprite = self.sprite, speed = laserSpeed, targetX = laserTargetX, targetY = laserTargetY })

    return self
end

function Laser:update()
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance < self.speed then
        -- Remove the sprite next frame
        if self.sprite then
            self.sprite:remove()
        end
        self.delete = true
        return
    end

    local angle = math.atan(dy, dx)
    self.x = self.x + self.speed * math.cos(angle)
    self.y = self.y + self.speed * math.sin(angle)

    local _, _, collisions, length = self.sprite:moveWithCollisions(self.x, self.y)
    -- move this to enemy?
    -- if length > 0 and collisions then
    --     for _, collision in ipairs(collisions) do
    --         local collisionTag = collision.other:getTag()
    --         if collisionTag == TAGS.enemy then
    --             -- Destroy enemy sprite, play sound, mark laser for deletion
    --             monsterDeathSound:play(1)
    --             local enemySprite = collision.other
    --             self.sprite:remove()
    --             self.delete = true

    --             for _, e in ipairs(enemies) do
    --                 if e.sprite == enemySprite or e.attackSprite == enemySprite then
    --                     e.sprite:remove()
    --                     if e.attackSprite then e.attackSprite:remove() end
    --                     e.delete = true
    --                     break
    --                 end
    --             end
    --         end
    --     end
    -- end
end

function Laser:remove()
    self.sprite:remove()
    self.delete = true
end

return Laser
