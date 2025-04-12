local pd <const> = playdate
local gfx <const> = playdate.graphics

local font = FONT
gfx.setFont(font)

GameOverScene = {}
class('GameOverScene').extends()

function GameOverScene:init()
    self.transitioning = false



    self.enteringScene = true
end

function GameOverScene:update()
    if not SceneManager.isTransitioning() then
        self.enteringScene = false
    else
        return
    end

    gfx.clear()
    gfx.drawTextAligned("Game Over!", 200, 30, kTextAlignment.center)
    gfx.drawTextAligned("Highest Building Count: " .. HIGHEST_BUILDING_COUNT, 200, 70, kTextAlignment.center)
    gfx.drawTextAligned("Total Buldings Placed: " .. TOTAL_BUILDINGS_PLACED, 200, 90, kTextAlignment.center)
    gfx.drawTextAligned("Lasers Shot: " .. LASERS_SHOT, 200, 110, kTextAlignment.center)
    gfx.drawTextAligned("Creatures Zapped: " .. ENEMIES_KILLED, 200, 130, kTextAlignment.center)
    gfx.drawTextAligned("Press A to Restart", 200, 220, kTextAlignment.center)

    if pd.buttonJustPressed(pd.kButtonA) and not self.transitioning then
        SceneManager.switchScene(GameScene)
        self.transitioning = true
    end
end
