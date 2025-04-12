local pd <const> = playdate
local gfx <const> = playdate.graphics

local font = FONT
gfx.setFont(font)

InstructionsScene = {}
class('InstructionsScene').extends()

function InstructionsScene:init()
    self.transitioning = false

    self.enteringScene = true
end

function InstructionsScene:update()
    if not SceneManager.isTransitioning() then
        self.enteringScene = false
    else
        return
    end

    gfx.clear()
    gfx.drawTextAligned("Controls", 200, 30, kTextAlignment.center)
    gfx.drawTextAligned("- Use the dpad to move the cursor", 10, 70, kTextAlignment.left)
    gfx.drawTextAligned("- Use the crank to rotate the moon", 10, 90, kTextAlignment.left)
    gfx.drawTextAligned("- Press A to place buildings or shoot lasers", 10, 110, kTextAlignment.left)
    gfx.drawTextAligned("- Press B to toggle building/laser mode", 10, 130, kTextAlignment.left)
    gfx.drawTextAligned("Press A to start", 200, 220, kTextAlignment.center)

    if pd.buttonJustPressed(pd.kButtonA) and not self.transitioning then
        SceneManager.switchScene(GameScene)
        self.transitioning = true
    end
end
