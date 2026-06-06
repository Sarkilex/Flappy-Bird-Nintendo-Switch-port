love.graphics.setDefaultFilter("nearest", "nearest")

local splashScreens = {}
local currentSplash = 1
local splashTimer = 0
local alpha = 0
local state = "fadein"
local FADE_SPEED = 2     
local HOLD_TIME = 1.5   
local gameState = "splash"
local isPaused = false

local logoMenu 
local playButton
local pauseButton
local menuButton
local restartButton
local backgroundImg 
local baseImg 
local pipeImg

local numberImages = {}

local sndSwoosh
local sndWing
local sndHit
local sndDie
local sndPoint

local score = 0
local highScore = 0
local isNewHighScore = false
local fontSplash

local bgScrollX = 0          
local bgSpeed = 80           

local birdFrames = {}
local birdSequence = {1, 2, 3, 2} 
local birdIndex = 1               
local birdTimer = 0
local birdAnimSpeed = 0.15        
local scale = 6                    

local transitionState = "none"
local transitionAlpha = 0
local TRANSITION_SPEED = 3

local pipes = {}
local pipeSpeed = 160
local pipeSpawnTimer = 0
local pipeSpawnInterval = 2.8 
local pipeGap = 140

local BIRD_SCALE = 2.0        
local PIPE_SCALE_X = 2.0      
local PIPE_SCALE_Y = 2.0      
local UI_SCALE = 5.0

local NUMBER_SCALE = 2.75 
local NUMBER_SPACING = 2 

local birdX = 200
local birdY = 300
local birdVelocity = 0
local birdGravity = 900
local birdJump = -290
local birdAngle = 0
local isDead = false

local btnPauseX, btnPauseY = 20, 20
local btnRestartX, btnRestartY = 0, 20
local btnMenuX, btnMenuY = 0, 20
local playX, playY, playW, playH = 0, 0, 0, 0

local birdColors = {"Yellow", "Red", "Blue"}
local currentBirdColor = "Yellow"

function changeBirdColor(color)
    currentBirdColor = color
    local birdPath = "Assets/Sprites/Birds/" .. currentBirdColor .. "/"
    
    birdFrames[1] = love.graphics.newImage(birdPath .. "1.png")
    birdFrames[2] = love.graphics.newImage(birdPath .. "2.png")
    birdFrames[3] = love.graphics.newImage(birdPath .. "3.png")
end

function pickRandomBird()
    local randomIndex = love.math.random(1, #birdColors)
    changeBirdColor(birdColors[randomIndex])
end

function pickRandomBackground()
    local bgPath = "Assets/Sprites/Other/"
    if love.math.random(1, 2) == 1 then
        backgroundImg = love.graphics.newImage(bgPath .. "background-day.png")
    else
        backgroundImg = love.graphics.newImage(bgPath .. "background-night.png")
    end
end

function resetGame()
    score = 0
    isNewHighScore = false
    pipes = {}
    birdY = 300
    birdVelocity = 0
    birdAngle = 0
    isDead = false
    pipeSpawnTimer = pipeSpawnInterval
end

function getScoreWidth(scoreNum)
    local scoreText = tostring(scoreNum)
    local totalWidth = 0
    
    for i = 1, #scoreText do
        local digit = tonumber(scoreText:sub(i, i))
        if numberImages[digit] then
            totalWidth = totalWidth + (numberImages[digit]:getWidth() * NUMBER_SCALE)
            if i < #scoreText then
                totalWidth = totalWidth + (NUMBER_SPACING * NUMBER_SCALE)
            end
        end
    end
    return totalWidth
end

function drawScore(scoreNum, yPos)
    local scoreText = tostring(scoreNum)
    local screenWidth = 1280
    local totalWidth = getScoreWidth(scoreNum)
    
    local startX = (screenWidth - totalWidth) / 2
    local currentX = startX
    
    love.graphics.setColor(1, 1, 1, 1)
    for i = 1, #scoreText do
        local digit = tonumber(scoreText:sub(i, i))
        local img = numberImages[digit]
        
        if img then
            love.graphics.draw(img, currentX, yPos, 0, NUMBER_SCALE, NUMBER_SCALE)
            currentX = currentX + (img:getWidth() * NUMBER_SCALE) + (NUMBER_SPACING * NUMBER_SCALE)
        end
    end
end

function love.load()
    love.math.setRandomSeed(os.time())

    local path = "Assets/Other/Logos/"

    splashScreens = {
        {
            { type = "image", data = love.graphics.newImage(path .. "dotgears.png") }
        },
        {
            { type = "image", data = love.graphics.newImage(path .. "love2d.png") }
        },
        {
            { type = "image", data = love.graphics.newImage(path .. "gbatemp.png"), offset = -180 },
            { type = "image", data = love.graphics.newImage(path .. "xda.png"), offset = 0 },
            { type = "text",  data = "Ported by Sarkilex", offset = 180 }
        }
    }
    
    fontSplash = love.graphics.newFont(40)

    for i = 0, 9 do
        numberImages[i] = love.graphics.newImage("Assets/Sprites/Numbers/" .. i .. ".png")
    end

    logoMenu = love.graphics.newImage("Assets/Other/UI/logo.png") 
    playButton = love.graphics.newImage("Assets/Other/UI/play.png")
    pauseButton = love.graphics.newImage("Assets/Other/UI/pause.png")
    menuButton = love.graphics.newImage("Assets/Other/UI/menu.png")
    restartButton = love.graphics.newImage("Assets/Other/UI/restart.png")
    
    baseImg = love.graphics.newImage("Assets/Sprites/Other/base.png")
    pipeImg = love.graphics.newImage("Assets/Sprites/Pipes/pipe-green.png")

    sndSwoosh = love.audio.newSource("Assets/Sounds/swoosh.wav", "static")
    sndWing = love.audio.newSource("Assets/Sounds/wing.wav", "static")
    sndHit = love.audio.newSource("Assets/Sounds/hit.wav", "static")
    sndDie = love.audio.newSource("Assets/Sounds/die.wav", "static")
    sndPoint = love.audio.newSource("Assets/Sounds/point.wav", "static")

    pickRandomBird()
    pickRandomBackground()

    local restartW = restartButton:getWidth() * UI_SCALE
    local menuW = menuButton:getWidth() * UI_SCALE

    btnRestartX = 1280 - 20 - restartW
    btnMenuX = btnRestartX - 20 - menuW

    local scalePlay = 4.8 
    playW = playButton:getWidth() * scalePlay
    playH = playButton:getHeight() * scalePlay
    playX = (1280 - playW) / 2
    playY = 390 
end

function love.update(dt)
    if gameState == "splash" then
        updateSplash(dt)
        return
    end

    if isPaused then
        return
    end

    if gameState == "menu" or gameState == "ready" or (gameState == "playing" and not isDead) then
        if backgroundImg then
            local screenHeight = 720
            local bgScaleY = screenHeight / backgroundImg:getHeight()
            local bgScaledWidth = backgroundImg:getWidth() * bgScaleY

            bgScrollX = (bgScrollX + bgSpeed * dt) % bgScaledWidth
        end

        birdTimer = birdTimer + dt
        if birdTimer >= birdAnimSpeed then
            birdTimer = birdTimer - birdAnimSpeed
            birdIndex = (birdIndex % #birdSequence) + 1
        end
    end

    if gameState == "ready" then
        birdY = 300 + math.sin(love.timer.getTime() * 5) * 10
    end

    if gameState == "playing" then
        if not isDead then
            birdVelocity = birdVelocity + birdGravity * dt
            birdY = birdY + birdVelocity * dt

            if birdVelocity < 150 then
                birdAngle = -0.2
            else
                birdAngle = birdAngle + 4 * dt
                if birdAngle > math.pi / 2 then
                    birdAngle = math.pi / 2
                end
            end

            pipeSpawnTimer = pipeSpawnTimer + dt
            if pipeSpawnTimer >= pipeSpawnInterval then
                pipeSpawnTimer = 0
                local minCenterY = 200
                local maxCenterY = 500
                local centerY = love.math.random(minCenterY, maxCenterY)
                table.insert(pipes, {
                    x = 1280,
                    centerY = centerY,
                    scored = false
                })
            end
        else
            if birdY < 720 then
                birdVelocity = birdVelocity + birdGravity * dt
                birdY = birdY + birdVelocity * dt
                birdAngle = math.pi / 2
            end
        end

        local birdImg = birdFrames[birdSequence[birdIndex]]
        local birdW = birdImg:getWidth() * BIRD_SCALE
        local birdH = birdImg:getHeight() * BIRD_SCALE
        local birdLeft = birdX - birdW / 2
        local birdTop = birdY - birdH / 2
        local pipeW = pipeImg:getWidth() * PIPE_SCALE_X

        for i = #pipes, 1, -1 do
            local p = pipes[i]
            if not isDead then
                p.x = p.x - pipeSpeed * dt
            end

            local topPipeBottomY = p.centerY - (pipeGap / 2)
            if birdLeft < p.x + pipeW and birdLeft + birdW > p.x and birdTop < topPipeBottomY then
                if not isDead then
                    isDead = true
                    if sndHit then sndHit:clone():play() end
                    if sndDie then sndDie:clone():play() end
                end
            end

            local bottomPipeTopY = p.centerY + (pipeGap / 2)
            if birdLeft < p.x + pipeW and birdLeft + birdW > p.x and birdTop + birdH > bottomPipeTopY then
                if not isDead then
                    isDead = true
                    if sndHit then sndHit:clone():play() end
                    if sndDie then sndDie:clone():play() end
                end
            end

            if p.x + pipeW < 0 then
                table.remove(pipes, i)
            else
                if not p.scored and p.x < birdX and not isDead then
                    p.scored = true
                    score = score + 1
                    if score > highScore then
                        highScore = score
                        isNewHighScore = true
                    end
                    if sndPoint then sndPoint:clone():play() end
                end
            end
        end

        if baseImg and backgroundImg then
            local baseScaleY = 720 / backgroundImg:getHeight()
            local baseScaledHeight = baseImg:getHeight() * baseScaleY
            local baseY = 720 - baseScaledHeight
            if birdTop + birdH > baseY then
                birdY = baseY - birdH / 2
                birdVelocity = 0
                if not isDead then
                    isDead = true
                    if sndHit then sndHit:clone():play() end
                end
            end
            if birdTop < 0 and not isDead then
                birdY = birdH / 2
                birdVelocity = 0
            end
        end
    end

    if transitionState == "fadeout" then
        transitionAlpha = transitionAlpha + TRANSITION_SPEED * dt
        if transitionAlpha >= 1 then
            transitionAlpha = 1
            resetGame()
            gameState = "ready"
            transitionState = "fadein"
            if sndSwoosh then sndSwoosh:clone():play() end
        end
    elseif transitionState == "to_menu" then
        transitionAlpha = transitionAlpha + TRANSITION_SPEED * dt
        if transitionAlpha >= 1 then
            transitionAlpha = 1
            resetGame()
            pickRandomBird()
            pickRandomBackground()
            gameState = "menu"
            transitionState = "fadein"
            if sndSwoosh then sndSwoosh:clone():play() end
        end
    elseif transitionState == "fadein" then
        transitionAlpha = transitionAlpha - TRANSITION_SPEED * dt
        if transitionAlpha <= 0 then
            transitionAlpha = 0
            transitionState = "none"
        end
    end
end

function love.draw()
    if gameState == "splash" then
        drawSplash()
        return
    end

    local screenWidth = 1280
    local screenHeight = 720
    love.graphics.setColor(1, 1, 1, 1)

    if backgroundImg then
        local bgScaleY = screenHeight / backgroundImg:getHeight() 
        local bgScaledWidth = backgroundImg:getWidth() * bgScaleY 
        for x = 0, screenWidth + bgScaledWidth, bgScaledWidth do
            love.graphics.draw(backgroundImg, x - bgScrollX, 0, 0, bgScaleY, bgScaleY)
        end
    end

    if gameState == "menu" then
        drawMenu()
    elseif gameState == "playing" or gameState == "ready" then
        drawGame()
    end

    if transitionState ~= "none" then
        love.graphics.setColor(0, 0, 0, transitionAlpha)
        love.graphics.rectangle("fill", 0, 0, 1280, 720)
        love.graphics.setColor(1, 1, 1, 1)
    end
end

function updateSplash(dt)
    if currentSplash > #splashScreens then
        gameState = "menu"
        if sndSwoosh then sndSwoosh:clone():play() end
        return
    end

    if state == "fadein" then
        alpha = alpha + FADE_SPEED * dt
        if alpha >= 1 then
            alpha = 1
            state = "hold"
            splashTimer = 0
        end
    elseif state == "hold" then
        splashTimer = splashTimer + dt
        if splashTimer >= HOLD_TIME then
            state = "fadeout"
        end
    elseif state == "fadeout" then
        alpha = alpha - FADE_SPEED * dt
        if alpha <= 0 then
            alpha = 0
            currentSplash = currentSplash + 1 
            state = "fadein"
            if currentSplash == #splashScreens + 1 then
                if sndSwoosh then sndSwoosh:clone():play() end
            end
        end
    end
end

function drawSplash()
    love.graphics.clear(0, 0, 0)
    local currentStep = splashScreens[currentSplash]
    if not currentStep then return end

    love.graphics.setColor(1, 1, 1, alpha)
    local screenWidth = 1280
    local screenHeight = 720

    for _, element in ipairs(currentStep) do
        local yOffset = element.offset or 0
        if element.type == "image" then
            local img = element.data
            local x = (screenWidth - img:getWidth()) / 2
            local y = ((screenHeight - img:getHeight()) / 2) + yOffset
            love.graphics.draw(img, x, y)
        elseif element.type == "text" then
            love.graphics.setFont(fontSplash)
            local textW = fontSplash:getWidth(element.data)
            local textH = fontSplash:getHeight()
            local x = (screenWidth - textW) / 2
            local y = ((screenHeight - textH) / 2) + yOffset
            love.graphics.print(element.data, x, y)
        end
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function drawMenu()
    local screenWidth = 1280
    local screenHeight = 720

    if baseImg then
        local baseScaleY = screenHeight / backgroundImg:getHeight() 
        local baseScaledWidth = baseImg:getWidth() * baseScaleY
        local baseScaledHeight = baseImg:getHeight() * baseScaleY
        local baseY = screenHeight - baseScaledHeight

        for x = 0, screenWidth + baseScaledWidth, baseScaledWidth do
            love.graphics.draw(baseImg, x - bgScrollX, baseY, 0, baseScaleY, baseScaleY)
        end
    end

    local logoW = logoMenu:getWidth() * scale
    local logoH = logoMenu:getHeight() * scale
    local logoX = (screenWidth - logoW) / 2
    local logoY = 50 
    love.graphics.draw(logoMenu, logoX, logoY, 0, scale, scale)

    local scalePlay = 4.8 
    love.graphics.draw(playButton, playX, playY, 0, scalePlay, scalePlay)

    local scaleBird = 3.8
    local currentFrame = birdSequence[birdIndex]
    local birdImg = birdFrames[currentFrame]

    if birdImg then
        local birdW = birdImg:getWidth() * scaleBird
        local birdH = birdImg:getHeight() * scaleBird
        local birdXPos = (screenWidth - birdW) / 2
        local middleY = (logoY + logoH + playY) / 2
        local birdYPos = middleY - (birdH / 2)

        love.graphics.draw(birdImg, birdXPos, birdYPos, 0, scaleBird, scaleBird)
    end
end

function drawGame()
    local screenWidth = 1280
    local screenHeight = 720

    if pipeImg and gameState == "playing" then
        for _, p in ipairs(pipes) do
            local topPipeBottomY = p.centerY - (pipeGap / 2)
            love.graphics.draw(pipeImg, p.x + (pipeImg:getWidth() * PIPE_SCALE_X), topPipeBottomY, math.pi, PIPE_SCALE_X, PIPE_SCALE_Y)

            local bottomPipeTopY = p.centerY + (pipeGap / 2)
            love.graphics.draw(pipeImg, p.x, bottomPipeTopY, 0, PIPE_SCALE_X, PIPE_SCALE_Y)
        end
    end

    if baseImg then
        local baseScaleY = screenHeight / backgroundImg:getHeight() 
        local baseScaledWidth = baseImg:getWidth() * baseScaleY
        local baseScaledHeight = baseImg:getHeight() * baseScaleY
        local baseY = screenHeight - baseScaledHeight
        for x = 0, screenWidth + baseScaledWidth, baseScaledWidth do
            love.graphics.draw(baseImg, x - bgScrollX, baseY, 0, baseScaleY, baseScaleY)
        end
    end

    local currentFrame = birdSequence[birdIndex]
    local birdImg = birdFrames[currentFrame]
    if birdImg then
        local ox = birdImg:getWidth() / 2
        local oy = birdImg:getHeight() / 2
        love.graphics.draw(birdImg, birdX, birdY, birdAngle, BIRD_SCALE, BIRD_SCALE, ox, oy)
    end

    if gameState == "ready" then
        love.graphics.setFont(fontSplash)
        local readyText = "PRESS (A) OR TAP SCREEN TO FLY"
        local readyW = fontSplash:getWidth(readyText)
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.print(readyText, (screenWidth - readyW) / 2 + 3, 203)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(readyText, (screenWidth - readyW) / 2, 200)
    end

    if pauseButton then
        love.graphics.draw(pauseButton, btnPauseX, btnPauseY, 0, UI_SCALE, UI_SCALE)
    end
    if restartButton then
        love.graphics.draw(restartButton, btnRestartX, btnRestartY, 0, UI_SCALE, UI_SCALE)
    end
    if menuButton then
        love.graphics.draw(menuButton, btnMenuX, btnMenuY, 0, UI_SCALE, UI_SCALE)
    end

    if not isDead then
        drawScore(score, 25)
    end

    if isPaused then
        love.graphics.setColor(0, 0, 0, 0.4)
        love.graphics.rectangle("fill", 0, 0, screenWidth, screenHeight)
        love.graphics.setColor(1, 1, 1, 1)
    end
    
    if isDead then
        love.graphics.setFont(fontSplash)
        
        local overText = "GAME OVER! PRESS (X) TO RESTART"
        local overW = fontSplash:getWidth(overText)
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.print(overText, (screenWidth - overW) / 2 + 3, 153)
        love.graphics.setColor(1, 0.2, 0.2, 1)
        love.graphics.print(overText, (screenWidth - overW) / 2, 150)
        
        local currentScoreText = "SCORE: " .. score
        local csW = fontSplash:getWidth(currentScoreText)
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.print(currentScoreText, (screenWidth - csW) / 2 + 3, 243)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(currentScoreText, (screenWidth - csW) / 2, 240)

        local highScoreText = "BEST: " .. highScore
        local hsW = fontSplash:getWidth(highScoreText)
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.print(highScoreText, (screenWidth - hsW) / 2 + 3, 303)
        love.graphics.setColor(1, 0.84, 0, 1)
        love.graphics.print(highScoreText, (screenWidth - hsW) / 2, 300)

        if isNewHighScore then
            local newText = "NEW HIGHSCORE!"
            local newW = fontSplash:getWidth(newText)
            love.graphics.setColor(0, 0, 0, 0.6)
            love.graphics.print(newText, (screenWidth - newW) / 2 + 3, 383)
            love.graphics.setColor(0.2, 1, 0.2, 1)
            love.graphics.print(newText, (screenWidth - newW) / 2, 380)
        end
    end
end

function love.mousepressed(x, y, button, istouch)
    if gameState == "splash" then
        alpha = 0
        currentSplash = currentSplash + 1
        state = "fadein"
        if sndSwoosh then sndSwoosh:clone():play() end
        if currentSplash > #splashScreens then
            gameState = "menu"
        end
        return
    end

    if gameState == "menu" and transitionState == "none" then
        if x >= playX and x <= playX + playW and y >= playY and y <= playY + playH then
            transitionState = "fadeout"
            if sndSwoosh then sndSwoosh:clone():play() end
        end

    elseif (gameState == "playing" or gameState == "ready") and transitionState == "none" then
        local pW = pauseButton:getWidth() * UI_SCALE
        local pH = pauseButton:getHeight() * UI_SCALE
        if x >= btnPauseX and x <= btnPauseX + pW and y >= btnPauseY and y <= btnPauseY + pH then
            if not isDead and gameState == "playing" then
                isPaused = not isPaused
                if sndSwoosh then sndSwoosh:clone():play() end
            end
            return
        end

        local rW = restartButton:getWidth() * UI_SCALE
        local rH = restartButton:getHeight() * UI_SCALE
        if x >= btnRestartX and x <= btnRestartX + rW and y >= btnRestartY and y <= btnRestartY + rH then
            isPaused = false
            pickRandomBird()
            pickRandomBackground()
            transitionState = "fadeout"
            return
        end

        local mW = menuButton:getWidth() * UI_SCALE
        local mH = menuButton:getHeight() * UI_SCALE
        if x >= btnMenuX and x <= btnMenuX + mW and y >= btnMenuY and y <= btnMenuY + mH then
            isPaused = false
            transitionState = "to_menu"
            return
        end

        if gameState == "ready" then
            gameState = "playing"
            birdVelocity = birdJump
            if sndWing then sndWing:clone():play() end
        elseif gameState == "playing" and not isPaused and not isDead then
            birdVelocity = birdJump
            if sndWing then sndWing:clone():play() end
        end
    end
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    love.mousepressed(x, y, "1", true)
end

function love.gamepadpressed(joystick, button)
    if gameState == "splash" and (button == "a" or button == "start") then
        alpha = 0
        currentSplash = currentSplash + 1
        state = "fadein"
        if sndSwoosh then sndSwoosh:clone():play() end
        if currentSplash > #splashScreens then
            gameState = "menu"
        end
    
    elseif gameState == "menu" then
        if (button == "a" or button == "start") and transitionState == "none" then
            transitionState = "fadeout"
        end

    elseif gameState == "ready" then
        if button == "a" and transitionState == "none" then
            gameState = "playing"
            birdVelocity = birdJump
            if sndWing then sndWing:clone():play() end
        end

    elseif gameState == "playing" then
        if (button == "start" or button == "back") and not isDead and transitionState == "none" then
            isPaused = not isPaused
            if sndSwoosh then sndSwoosh:clone():play() end
        end

        if button == "x" and transitionState == "none" then
            isPaused = false
            pickRandomBird()
            pickRandomBackground()
            transitionState = "fadeout"
        end

        if button == "y" and transitionState == "none" then
            isPaused = false
            transitionState = "to_menu"
        end

        if not isPaused and button == "a" and transitionState == "none" and not isDead then
            birdVelocity = birdJump
            if sndWing then sndWing:clone():play() end
        end
    end
end