import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"

local gfx <const> = playdate.graphics
local titleFont = gfx.font.new('font/MVP')
local font = gfx.font.new('font/Mini Sans 2X')

--buttons

local sprite_A = gfx.sprite.new()
sprite_A:setImage(gfx.image.new("images/sprite_A"))
sprite_A:setVisible(false)
sprite_A:moveTo(200, 120)
sprite_A:add()

local sprite_B = gfx.sprite.new()
sprite_B:setImage(gfx.image.new("images/sprite_B"))
sprite_B:setVisible(false)
sprite_B:moveTo(200, 120)
sprite_B:add()

--pad

local sprite_Up = gfx.sprite.new()
sprite_Up:setImage(gfx.image.new("images/sprite_Up"))
sprite_Up:setVisible(false)
sprite_Up:moveTo(200, 120)
sprite_Up:add()

local sprite_Down = gfx.sprite.new()
sprite_Down:setImage(gfx.image.new("images/sprite_Down"))
sprite_Down:setVisible(false)
sprite_Down:moveTo(200, 120)
sprite_Down:add()

local sprite_Left = gfx.sprite.new()
sprite_Left:setImage(gfx.image.new("images/sprite_Left"))
sprite_Left:setVisible(false)
sprite_Left:moveTo(200, 120)
sprite_Left:add()

local sprite_Right = gfx.sprite.new()
sprite_Right:setImage(gfx.image.new("images/sprite_Right"))
sprite_Right:setVisible(false)
sprite_Right:moveTo(200, 120)
sprite_Right:add()

--crank

local sprite_CrankBackward = gfx.sprite.new()
sprite_CrankBackward:setImage(gfx.image.new("images/sprite_CrankBackward"))
sprite_CrankBackward:setVisible(false)
sprite_CrankBackward:moveTo(200, 120)
sprite_CrankBackward:add()

local sprite_CrankForward = gfx.sprite.new()
sprite_CrankForward:setImage(gfx.image.new("images/sprite_CrankForward"))
sprite_CrankForward:setVisible(false)
sprite_CrankForward:moveTo(200, 120)
sprite_CrankForward:add()

--tilt

local sprite_TiltUp = gfx.sprite.new()
sprite_TiltUp:setImage(gfx.image.new("images/sprite_TiltUp"))
sprite_TiltUp:setVisible(false)
sprite_TiltUp:moveTo(200, 120)
sprite_TiltUp:add()

local sprite_TiltDown = gfx.sprite.new()
sprite_TiltDown:setImage(gfx.image.new("images/sprite_TiltDown"))
sprite_TiltDown:setVisible(false)
sprite_TiltDown:moveTo(200, 120)
sprite_TiltDown:add()

local sprite_TiltLeft = gfx.sprite.new()
sprite_TiltLeft:setImage(gfx.image.new("images/sprite_TiltLeft"))
sprite_TiltLeft:setVisible(false)
sprite_TiltLeft:moveTo(200, 120)
sprite_TiltLeft:add()

local sprite_TiltRight = gfx.sprite.new()
sprite_TiltRight:setImage(gfx.image.new("images/sprite_TiltRight"))
sprite_TiltRight:setVisible(false)
sprite_TiltRight:moveTo(200, 120)
sprite_TiltRight:add()

local deltaTime
local deltaTimeMultiplier <const> = 15

local currentAction = nil
local playerInput = nil
local score = 0
local reactionTime = 150
local reactionTimer = 0
local input
local tiltThreshold = 1

-- Define game states
local STATE_MENU = "menu"
local STATE_GAME = "game"
local STATE_GAMEOVER = "gameOver"

-- Game state variable
local currentState = STATE_MENU

local actions = {
	{name = "A", sprite = sprite_A},
	{name = "B = ", sprite = sprite_B},
	{name = "Up = ", sprite = sprite_Up},
	{name = "Down ", sprite = sprite_Down},
	{name = "Left ", sprite = sprite_Left},
	{name = "Right", sprite = sprite_Right},
	{name = "CrankForward ", sprite = sprite_CrankForward},
	{name = "CrankBackward", sprite = sprite_CrankBackward},
	{name = "TiltUp = ", sprite = sprite_TiltUp},
	{name = "TiltDown ", sprite = sprite_TiltDown},
	{name = "TiltLeft ", sprite = sprite_TiltLeft},
	{name = "TiltRight", sprite = sprite_TiltRight}
}

local function startNewRound()
    currentAction = math.random(1, #actions)
    showingSequence = true
    userTurn = false
    reactionTimer = reactionTime
    reactionTime = math.max(30, reactionTime - 5) -- Decrease time limit each round
    playerInput = nil
end

-- Initialize the game
local function loadGame()
    playdate.startAccelerometer()
    playdate.display.setRefreshRate(50)
    math.randomseed(playdate.getSecondsSinceEpoch())
    score = 0
    currentState = STATE_GAME
end

-- Reset the game when the player loses
local function resetGame()
    playerInput = nil
    showingSequence = false
    currentState = STATE_GAMEOVER
end

-- Update menu logic
local function updateMenu()
    score = 0
    if playdate.buttonJustPressed(playdate.kButtonA) then
        loadGame()
    end
end

local screenShakeDuration = 0.2  -- Duration of screen shake in seconds
local screenShakeIntensity = 4  -- How much the screen shakes
local currentShakeTime = 0  -- Tracks remaining shake time
local originalOffsetX, originalOffsetY = 0, 0  -- Used to store the original screen offset

local function applyScreenShake()
    if currentShakeTime > 0 then
        -- Reduce shake time
        currentShakeTime = currentShakeTime - deltaTime

        -- Calculate random offset
        local offsetX = math.random(-screenShakeIntensity, screenShakeIntensity)
        local offsetY = math.random(-screenShakeIntensity, screenShakeIntensity)
        
        -- Apply offset to screen
        gfx.setDrawOffset(offsetX, offsetY)
    else
        -- Reset screen offset to original position
        gfx.setDrawOffset(originalOffsetX, originalOffsetY)
    end
end
local function detectCrank()
    local crankInput = playdate.getCrankChange()

    if crankInput > 1 then -- Crank forward
        return 7
    elseif crankInput < -1 then -- Crank backward
        return 8
    end
    return input
end
local function detectTilt()
    local gravityX, gravityY, gravityZ = playdate.readAccelerometer()

    if gravityY < -tiltThreshold then
        return 9 -- Tilt Up
    elseif gravityY > tiltThreshold then
        return 10 -- Tilt Down
    elseif gravityX < -tiltThreshold then
        return 11 -- Tilt Left
    elseif gravityX > tiltThreshold then
        return 12 -- Tilt Right
    end
    return input
end
local function detectButton()
    if playdate.buttonJustPressed(playdate.kButtonA) then
        return 1
    elseif playdate.buttonJustPressed(playdate.kButtonB) then
        return 2
    elseif playdate.buttonJustPressed(playdate.kButtonUp) then
        return 3
    elseif playdate.buttonJustPressed(playdate.kButtonDown) then
        return 4
    elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
        return 5
    elseif playdate.buttonJustPressed(playdate.kButtonRight) then
        return 6
    end
    return input
end
-- Update game logic
local function updateGame()
    reactionTimer = reactionTimer - (deltaTime * deltaTimeMultiplier)
    
    input = nil
    input = detectButton()
    input = detectTilt()
    input = detectCrank()

    if reactionTimer <= 0 then
        resetGame()
    end

    if input ~= nil then
        playerInput = input
        if playerInput ~= currentAction then
            --resetGame()
            currentShakeTime = screenShakeDuration
        else
            score = score + 1
            startNewRound()
        end
    end
end

-- Update game over logic
local function updateGameOver()
    if playdate.buttonJustPressed(playdate.kButtonA) then
        currentState = STATE_MENU
    end
end

-- Draw menu
local function drawMenu()
    gfx.setFont(titleFont)
    gfx.drawText("SIMON SAYS", 100, 80)
    gfx.setFont(font)
    gfx.drawText("Press A to Start", 100, 120)
end

-- Draw game over screen
local function drawGameOver()
    gfx.drawText("Game Over!", 100, 80)
    gfx.drawText("Final Score: " .. score, 100, 100)
    gfx.drawText("Press A to \nreturn to menu", 100, 140)
end
-- Define the dimensions and position of the reaction time bar
local barX = 0
local barY = 230
local barHeight = 10
local barMaxWidth = 400 -- Maximum width of the bar when fully charged

-- Draw game graphics
local function drawGame()

    for key, value in pairs(actions) do
        if key == currentAction then
            value.sprite:setVisible(true)
        else
            value.sprite:setVisible(false)
        end
    end
    applyScreenShake()
    gfx.sprite.update()

    -- Calculate the current width of the bar based on reactionTimer
    local currentBarWidth = (reactionTimer / reactionTime) * barMaxWidth

    -- Draw the bar background (optional, so you can see the outline of the bar)
    gfx.setColor(gfx.kColorWhite)
    gfx.fillRect(barX, barY, barMaxWidth, barHeight) -- Draw the background in white

    -- Draw the actual shrinking bar
    gfx.setColor(gfx.kColorBlack)
    gfx.fillRect(barX, barY, currentBarWidth, barHeight) -- Draw the bar based on the remaining time

    gfx.setColor(gfx.kColorBlack)
    gfx.drawText("Score: " .. score, 10, 10)
end
-- Main update loop
function playdate.update()
    gfx.clear()
    deltaTime = playdate.getElapsedTime()

    if currentState == STATE_MENU then
        updateMenu()
        drawMenu()
    elseif currentState == STATE_GAME then
        updateGame()
        drawGame()
    elseif currentState == STATE_GAMEOVER then
        updateGameOver()
        drawGameOver()
    end
    playdate.resetElapsedTime()
end
