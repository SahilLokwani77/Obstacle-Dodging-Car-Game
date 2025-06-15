-- main.lua

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600

function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {fullscreen=false, resizable=false})
    love.window.setTitle("Obstacle Dodging Car Game")

    background = love.graphics.newImage("assets/background.png")
    carImg = love.graphics.newImage("assets/car.png")
    obstacleImg = love.graphics.newImage("assets/obstacle.png")
    powerupImg = love.graphics.newImage("assets/powerup.png")
    explosionImg = love.graphics.newImage("assets/explosion.png")

    bgY = 0

    car = {
        x = WINDOW_WIDTH / 2 - 60,
        y = WINDOW_HEIGHT - 150,
        width = 120,
        height = 210,
        speed = 700,
        lives = 3
    }

    obstacles = {}
    powerups = {}
    explosion = nil

    obstacleTimer = 0
    powerupTimer = 0
    multiplierTimer = 0
    score = 0
    multiplierActive = false

    gameOver = false
    gamePaused = false

    bgm = love.audio.newSource("assets/bgm.mp3", "stream")
    crashSound = love.audio.newSource("assets/crash.wav", "static")
    pickupSound = love.audio.newSource("assets/pickup.wav", "static")
    powerupSpeedSound = love.audio.newSource("assets/powerup_speed.wav", "static")
    powerupShieldSound = love.audio.newSource("assets/powerup_shield.wav", "static")
    engineRevSound = love.audio.newSource("assets/engine_rev.wav", "static")

    bgm:setLooping(true)
    bgm:setVolume(0.3)
    bgm:play()

    engineRevSound:setLooping(true)
    engineRevSound:setVolume(0.3)
    engineRevSound:play()

    crashSound:setVolume(1.0)
    pickupSound:setVolume(0.8)
    powerupSpeedSound:setVolume(0.9)
    powerupShieldSound:setVolume(0.9)
end

function love.update(dt)
    if gamePaused or gameOver then return end

    bgY = (bgY + 180 * dt) % background:getHeight()

    if love.keyboard.isDown("left") then
        car.x = car.x - car.speed * dt
    end
    if love.keyboard.isDown("right") then
        car.x = car.x + car.speed * dt
    end
    if love.keyboard.isDown("up") then
        car.y = car.y - car.speed * dt
    end
    if love.keyboard.isDown("down") then
        car.y = car.y + car.speed * dt
    end

    car.x = math.max(0, math.min(WINDOW_WIDTH - car.width, car.x))
    car.y = math.max(0, math.min(WINDOW_HEIGHT - car.height, car.y))

    obstacleTimer = obstacleTimer + dt
    if obstacleTimer > 1.5 then
        obstacleTimer = 0
        table.insert(obstacles, {
            x = math.random(0, WINDOW_WIDTH - 40),
            y = -40,
            width = 40,
            height = 30,
            speed = 100
        })
    end

    for i = #obstacles, 1, -1 do
        local obs = obstacles[i]
        obs.y = obs.y + obs.speed * dt
        if checkCollision(car, obs) then
            table.remove(obstacles, i)
            car.lives = car.lives - 1
            explosion = {x = car.x, y = car.y, timer = 0.5}
            crashSound:play()
            if car.lives <= 0 then
                gameOver = true
                bgm:stop()
                engineRevSound:stop()
            end
        elseif obs.y > WINDOW_HEIGHT then
            table.remove(obstacles, i)
        end
    end

    powerupTimer = powerupTimer + dt
    if powerupTimer > 8 then
        powerupTimer = 0
        table.insert(powerups, {
            x = math.random(0, WINDOW_WIDTH - 16),
            y = -16,
            width = 16,
            height = 16,
            speed = 100
        })
    end

    for i = #powerups, 1, -1 do
        local p = powerups[i]
        p.y = p.y + p.speed * dt
        if checkCollision(car, p) then
            multiplierActive = true
            multiplierTimer = 5
            table.remove(powerups, i)
            pickupSound:play()
            powerupSpeedSound:play()
        elseif p.y > WINDOW_HEIGHT then
            table.remove(powerups, i)
        end
    end

    if multiplierActive then
        multiplierTimer = multiplierTimer - dt
        if multiplierTimer <= 0 then
            multiplierActive = false
        end
    end

    if not gameOver then
        score = score + dt * (multiplierActive and 2 or 1)
    end

    if explosion then
        explosion.timer = explosion.timer - dt
        if explosion.timer <= 0 then
            explosion = nil
        end
    end
end

function checkCollision(a, b)
    return a.x < b.x + b.width and
           b.x < a.x + a.width and
           a.y < b.y + b.height and
           b.y < a.y + a.height
end

function love.draw()
    for y = -background:getHeight(), WINDOW_HEIGHT, background:getHeight() do
        for x = 0, WINDOW_WIDTH, background:getWidth() do
            love.graphics.draw(background, x, y + bgY)
        end
    end

    love.graphics.draw(carImg, car.x, car.y, 0, car.width / carImg:getWidth(), car.height / carImg:getHeight())

    for _, obs in ipairs(obstacles) do
        love.graphics.draw(obstacleImg, obs.x, obs.y, 0, obs.width / obstacleImg:getWidth(), obs.height / obstacleImg:getHeight())
    end

    for _, p in ipairs(powerups) do
        love.graphics.draw(powerupImg, p.x, p.y, 0, p.width / powerupImg:getWidth(), p.height / powerupImg:getHeight())
    end

    if explosion then
        love.graphics.draw(explosionImg, explosion.x, explosion.y)
    end

    love.graphics.print("Score: " .. math.floor(score), 10, 10)
    love.graphics.print("Lives: " .. car.lives, 10, 30)

    if multiplierActive then
        love.graphics.setColor(1, 1, 0)
        love.graphics.print("Score x2!", 10, 50)
        love.graphics.setColor(1, 1, 1)
    end

    if gameOver then
        love.graphics.printf("Game Over! Press R to Restart", 0, WINDOW_HEIGHT / 2, WINDOW_WIDTH, "center")
    elseif gamePaused then
        love.graphics.printf("Paused. Press P to Resume", 0, WINDOW_HEIGHT / 2, WINDOW_WIDTH, "center")
    end
end

function love.keypressed(key)
    if key == "r" and gameOver then
        love.event.quit("restart")
    elseif key == "p" then
        gamePaused = not gamePaused
    end
end
