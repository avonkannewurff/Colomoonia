local pd <const> = playdate
local gfx <const> = playdate.graphics
local assets <const> = Assets
local utilities <const> = Utilities

WeaponManager = {}
class('WeaponManager').extends()

function WeaponManager:init()
    self.weapons = {}
    self.maxWeapons = 5
    return self
end

function WeaponManager:addWeapon(weapon)
    table.insert(self.weapons, weapon)
end

function WeaponManager:update(dt)
    for i = 1, #self.weapons do
        local weapon = self.weapons[i]
        weapon:update(dt)
    end

    self:removeWeapons()
end

function WeaponManager:removeWeapons()
    for i = #self.weapons, 1, -1 do
        if self.weapons[i].delete then
            table.remove(self.weapons, i)
        end
    end
end

function WeaponManager:fireLaser(laserCursorSprite)
    if #self.weapons < self.maxWeapons then
        table.insert(self.weapons, Laser:new(laserCursorSprite))
    end
end

function WeaponManager:stop()
    for i = 1, #self.weapons do
        local weapon = self.weapons[i]
        weapon:stop()
    end
end
