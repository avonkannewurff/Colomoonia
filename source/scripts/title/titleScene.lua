local pd <const> = playdate
local gfx <const> = playdate.graphics
local audioManager <const> = AudioManager

local font = FONT
gfx.setFont(font)

TitleScene = {}
class('TitleScene').extends()

function TitleScene:init()
    self.transitioning = false

    audioManager.playSong(audioManager.songs.ambientSpace)

    gfx.clear()
    gfx.drawTextAligned("Colomoonia!", 200, 30, kTextAlignment.center)
    gfx.drawTextAligned("Colonize the moon! Build your colony", 200, 100, kTextAlignment.center)
    gfx.drawTextAligned("and protect it from moon creatures!", 200, 120, kTextAlignment.center)
    gfx.drawTextAligned("Press A to continue", 200, 220, kTextAlignment.center)

    self.enteringScene = true
end

function TitleScene:update()
    if not SceneManager.isTransitioning() then
        self.enteringScene = false
    else
        return
    end

    if pd.buttonJustPressed(pd.kButtonA) and not self.transitioning then
        SceneManager.switchScene(InstructionsScene)
        self.transitioning = true
    end
end
