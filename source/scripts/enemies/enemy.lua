local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities

Enemy = {}
class('Enemy').extends(gfx.sprite)

function Enemy:init(x, y)
    self:setZIndex(Z_INDEXES.enemy)
    self:moveTo(x, y)
    self:add()

    self:setTag(TAGS.enemy)
    self:setGroups(TAGS.enemy)
    self:setCollidesWithGroups({ TAGS.player, TAGS.enemy })

    self.stopped = false
end

function Enemy:collisionResponse()
    return gfx.sprite.kCollisionTypeOverlap
end

function Enemy:stop()
    self.stopped = true
end
